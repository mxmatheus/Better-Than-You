import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/challenge/challenge_config.dart';
import '../../domain/challenge/challenge_evidence.dart';
import '../../domain/challenge/challenge_registry.dart';
import '../../domain/challenge/challenge_type.dart';
import '../../domain/match/match_repository.dart';
import '../../domain/match/match_session.dart';
import '../../domain/match/mock_match_repository.dart';
import '../../domain/match/round_result.dart';
import '../../domain/match/match_state.dart';
import '../challenges/widgets/memory_challenge_widget.dart';
import '../challenges/widgets/precision_challenge_widget.dart';
import '../challenges/widgets/reaction_challenge_widget.dart';
import 'match_summary_screen.dart';
import 'widgets/match_hud.dart';
import 'widgets/split_comparison_card.dart';

class MatchScreen extends StatefulWidget {
  final MatchRepository repository;
  final int? matchSeed;

  const MatchScreen({
    super.key,
    this.repository = const MockMatchRepository(),
    this.matchSeed,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late MatchSession _session;
  bool _isLoading = true;
  bool _isShowingSplitCard = false;
  RoundResult? _latestRoundResult;

  @override
  void initState() {
    super.initState();
    _initMatch();
  }

  void _initMatch() async {
    final session = await widget.repository.createMatch(seed: widget.matchSeed);
    if (!mounted) return;
    setState(() {
      _session = session;
      _isLoading = false;
    });
  }

  void _handleEvidenceSubmitted(ChallengeEvidence evidence) async {
    if (_isShowingSplitCard) return;

    final roundResult = await widget.repository.submitRoundEvidence(
      session: _session,
      evidence: evidence,
    );

    var playerWins = _session.playerWins;
    var oppWins = _session.opponentWins;

    if (roundResult.outcome == RoundOutcome.win) {
      playerWins++;
    } else if (roundResult.outcome == RoundOutcome.loss) {
      oppWins++;
    }

    final updatedHistory = List<RoundResult>.from(_session.history)..add(roundResult);

    if (!mounted) return;
    setState(() {
      _latestRoundResult = roundResult;
      _session = _session.copyWith(
        playerWins: playerWins,
        opponentWins: oppWins,
        history: updatedHistory,
      );
      _isShowingSplitCard = true;
    });
  }

  void _handleContinue() async {
    if (_session.isMatchOver) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MatchSummaryScreen(session: _session),
        ),
      );
      return;
    }

    final updatedSession = await widget.repository.nextRound(_session);
    if (!mounted) return;
    setState(() {
      _session = updatedSession;
      _isShowingSplitCard = false;
      _latestRoundResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final currentType = _session.currentChallengeType;
    final def = ChallengeRegistry.getDefinition(currentType);
    final config = def.generator.generate(_session.currentRoundSeed);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD
            MatchHud(session: _session),

            // Main Challenge Area or Split Card
            Expanded(
              child: Stack(
                children: [
                  // Active Challenge Widget (Keyed to round index for clean reset)
                  KeyedSubtree(
                    key: ValueKey('round_${_session.currentRoundIndex}_$currentType'),
                    child: _buildChallengeWidget(currentType, config),
                  ),

                  // Split Comparison Card Overlay
                  if (_isShowingSplitCard && _latestRoundResult != null)
                    Container(
                      color: Colors.black87,
                      child: SplitComparisonCard(
                        roundResult: _latestRoundResult!,
                        onContinue: _handleContinue,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeWidget(ChallengeType type, ChallengeConfig config) {
    switch (type) {
      case ChallengeType.reaction:
        return ReactionChallengeWidget(
          config: config as ReactionConfig,
          onComplete: _handleEvidenceSubmitted,
        );
      case ChallengeType.memory:
        return MemoryChallengeWidget(
          config: config as MemoryConfig,
          onComplete: _handleEvidenceSubmitted,
        );
      case ChallengeType.precision:
        return PrecisionChallengeWidget(
          config: config as PrecisionConfig,
          onComplete: _handleEvidenceSubmitted,
        );
    }
  }
}
