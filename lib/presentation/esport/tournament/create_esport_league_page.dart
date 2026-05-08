import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/esport/tournament/cost/collapsible_cost_config.dart';
import 'package:pes_arena/presentation/esport/tournament/cost/cost_config_form.dart';
import 'package:pes_arena/widgets/gn_circle_avatar.dart';

typedef OnAddLeagueCallback =
    Future<String> Function({
      required String name,
      required String groupId,
      DateTime? startDate,
      DateTime? endDate,
      required String description,
      required bool rankPayoutEnabled,
      required List<int> rankPayouts,
      required int defaultMatchCost,
      required TournamentMode mode,
      required List<String> participants,
      required int groupCount,
      required int advanceCount,
      required List<String> knockoutSeeding,
      required Map<String, int> groupAssignment,
    });

typedef MemberInfo = ({String name, String? photoUrl});
typedef MemberNameLoader =
    Future<Map<String, MemberInfo>> Function(List<String> ids);

Future<Map<String, MemberInfo>> _defaultNameLoader(List<String> ids) async {
  final users = await getIt<GNFirestore>().getUsersById(ids);
  return users.map(
    (id, u) => MapEntry(id, (name: u.displayName ?? id, photoUrl: u.photoUrl)),
  );
}

class CreateEsportLeaguePage extends StatefulWidget {
  final List<GNEsportGroup> groups;
  final OnAddLeagueCallback onAddLeague;
  final MemberNameLoader memberNameLoader;

  const CreateEsportLeaguePage({
    super.key,
    required this.groups,
    required this.onAddLeague,
    this.memberNameLoader = _defaultNameLoader,
  });

  @override
  State<CreateEsportLeaguePage> createState() => _CreateEsportLeaguePageState();
}

class _CreateEsportLeaguePageState extends State<CreateEsportLeaguePage> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1
  GNEsportGroup? _selectedGroup;
  Map<String, MemberInfo> _memberInfo = {}; // id → (name, photoUrl)

  // Step 2
  final List<String> _selectedParticipantIds = [];

  // Step 2 — mode selection
  TournamentMode _mode = TournamentMode.league;

  // Step 3 — config & preview
  // cup: seeded order (index 0 = seed 1)
  List<String> _seededOrder = [];
  // full: userId → group index
  Map<String, int> _groupAssignment = {};
  // full: position strings like ["A1","B1","A2","B2"]
  List<String> _knockoutSeeding = [];
  int _groupCount = 2;
  int _advanceCount = 2;

  // Step 4 — info
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final _costFormKey = GlobalKey<CostConfigFormState>();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    if (widget.groups.length == 1) {
      final g = widget.groups.first;
      _selectedGroup = g;
      widget.memberNameLoader(g.members).then((info) {
        if (mounted) setState(() => _memberInfo = info);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  List<String> get _activeMembers {
    if (_selectedGroup == null) return [];
    final deactivated = _selectedGroup!.deactivatedMembers.toSet();
    return _selectedGroup!.members
        .where((id) => !deactivated.contains(id))
        .toList();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedGroup != null;
      case 1:
        return _selectedParticipantIds.length >= 2;
      case 2:
        return true; // mode selection — always OK
      case 3:
        if (_mode == TournamentMode.cup) {
          final n = _seededOrder.isEmpty
              ? _selectedParticipantIds.length
              : _seededOrder.length;
          return n >= 2 && (n & (n - 1)) == 0;
        }
        if (_mode == TournamentMode.full) {
          final k = _groupCount * _advanceCount;
          return k >= 2 && (k & (k - 1)) == 0 && _knockoutSeeding.length == k;
        }
        return true;
      case 4:
        return _nameController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  List<String> _defaultKnockoutSeeding() {
    final labels = List.generate(
      _groupCount,
      (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
    );
    return [
      for (int r = 1; r <= _advanceCount; r++)
        for (final l in labels) '$l$r',
    ];
  }

  void _initStep4() {
    if (_mode == TournamentMode.cup) {
      _seededOrder = List.from(_selectedParticipantIds);
    } else if (_mode == TournamentMode.full) {
      _groupAssignment = {
        for (int i = 0; i < _selectedParticipantIds.length; i++)
          _selectedParticipantIds[i]: i % _groupCount,
      };
      _knockoutSeeding = _defaultKnockoutSeeding();
    }
  }

  void _goNext() {
    if (_currentStep == 0 && _selectedGroup == null) {
      showToast('Bạn cần chọn nhóm');
      return;
    }
    if (_currentStep == 1 && _selectedParticipantIds.length < 2) {
      showToast('Cần chọn ít nhất 2 người tham gia');
      return;
    }
    if (_currentStep == 2) {
      // Transitioning mode select → config: initialise step 4 state
      setState(() => _initStep4());
    }
    if (_currentStep == 3) {
      // Validate config before advancing to info step
      if (_mode == TournamentMode.cup) {
        final n = _seededOrder.isEmpty
            ? _selectedParticipantIds.length
            : _seededOrder.length;
        if (n < 2 || (n & (n - 1)) != 0) {
          showToast('Cup cần số người là lũy thừa của 2 (2, 4, 8, 16...)');
          return;
        }
      }
      if (_mode == TournamentMode.full) {
        final knockoutSize = _groupCount * _advanceCount;
        if (knockoutSize < 2 || (knockoutSize & (knockoutSize - 1)) != 0) {
          showToast('Số bảng × số lên knockout phải là lũy thừa của 2');
          return;
        }
      }
    }
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      showToast('Bạn cần nhập tên giải đấu');
      return;
    }
    if (_startDate != null &&
        _endDate != null &&
        _startDate!.isAfter(_endDate!)) {
      showToast('Ngày bắt đầu phải trước ngày kết thúc');
      return;
    }
    final cost = _costFormKey.currentState?.validateAndCollect();
    if (cost == null) return;

    final knockoutSeeding = switch (_mode) {
      TournamentMode.cup => _seededOrder,
      TournamentMode.full => _knockoutSeeding,
      TournamentMode.league => const <String>[],
    };
    final groupAssignment = _mode == TournamentMode.full
        ? _groupAssignment
        : const <String, int>{};

    final participants = _mode == TournamentMode.cup && _seededOrder.isNotEmpty
        ? _seededOrder
        : _selectedParticipantIds;

    if (_mode == TournamentMode.cup) {
      final n = participants.length;
      if (n < 2 || (n & (n - 1)) != 0) {
        showToast('Cup cần số người là lũy thừa của 2 (2, 4, 8, 16...)');
        return;
      }
    }

    final leagueId = await widget.onAddLeague(
      name: _nameController.text.trim(),
      groupId: _selectedGroup!.id,
      startDate: _startDate,
      endDate: _endDate,
      description: _descController.text.trim(),
      rankPayoutEnabled: cost.rankPayoutEnabled,
      rankPayouts: cost.rankPayouts,
      defaultMatchCost: cost.defaultMatchCost,
      mode: _mode,
      participants: participants,
      groupCount: _groupCount,
      advanceCount: _advanceCount,
      knockoutSeeding: knockoutSeeding,
      groupAssignment: groupAssignment,
    );
    if (mounted) Navigator.of(context).pop(leagueId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.secondary.withValues(alpha: 0.16),
              theme.scaffoldBackgroundColor,
              colorScheme.primary.withValues(alpha: 0.06),
            ],
            stops: const [0, 0.46, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildStepIndicator(context),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Step1SelectGroup(
                      groups: widget.groups,
                      selected: _selectedGroup,
                      onSelect: (g) {
                        setState(() {
                          _selectedGroup = g;
                          _selectedParticipantIds.clear();
                          _seededOrder.clear();
                          _memberInfo = {};
                        });
                        widget.memberNameLoader(g.members).then((info) {
                          if (mounted) setState(() => _memberInfo = info);
                        });
                      },
                    ),
                    _Step2AddParticipants(
                      memberIds: _activeMembers,
                      memberInfo: _memberInfo,
                      selected: _selectedParticipantIds,
                      onToggle: (id) => setState(() {
                        if (_selectedParticipantIds.contains(id)) {
                          _selectedParticipantIds.remove(id);
                        } else {
                          _selectedParticipantIds.add(id);
                        }
                      }),
                    ),
                    _Step3ModeConfig(
                      mode: _mode,
                      onModeChange: (m) => setState(() => _mode = m),
                    ),
                    _Step4ConfigPreview(
                      mode: _mode,
                      participants: _selectedParticipantIds,
                      memberInfo: _memberInfo,
                      seededOrder: _seededOrder,
                      groupCount: _groupCount,
                      advanceCount: _advanceCount,
                      groupAssignment: _groupAssignment,
                      knockoutSeeding: _knockoutSeeding,
                      onSeededOrderChange: (order) =>
                          setState(() => _seededOrder = order),
                      onGroupCountChange: (v) => setState(() {
                        _groupCount = v;
                        _groupAssignment = {
                          for (
                            int i = 0;
                            i < _selectedParticipantIds.length;
                            i++
                          )
                            _selectedParticipantIds[i]: i % v,
                        };
                        _knockoutSeeding = _defaultKnockoutSeeding();
                      }),
                      onAdvanceCountChange: (v) => setState(() {
                        _advanceCount = v;
                        _knockoutSeeding = _defaultKnockoutSeeding();
                      }),
                      onGroupAssignmentChange: (a) =>
                          setState(() => _groupAssignment = a),
                      onKnockoutSeedingChange: (s) =>
                          setState(() => _knockoutSeeding = s),
                    ),
                    _Step4Info(
                      nameController: _nameController,
                      descController: _descController,
                      startDate: _startDate,
                      endDate: _endDate,
                      costFormKey: _costFormKey,
                      isBracketMode:
                          _mode == TournamentMode.cup ||
                          _mode == TournamentMode.full,
                      onStartDatePicked: (d) => setState(() {
                        _startDate = d;
                        if (_endDate != null && d.isAfter(_endDate!)) {
                          _endDate = null;
                        }
                      }),
                      onEndDatePicked: (d) => setState(() => _endDate = d),
                    ),
                  ],
                ),
              ),
              _buildNavButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              'assets/svg/trophy-solid.svg',
              colorFilter: ColorFilter.mode(
                colorScheme.onSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tạo giải đấu',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '${_currentStep + 1}/5',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(5, (i) {
          final active = i <= _currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
              decoration: BoxDecoration(
                color: active
                    ? colorScheme.secondary
                    : colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLast = _currentStep == 4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _goBack,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(50, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: _canProceed ? _goNext : null,
              icon: Icon(
                isLast
                    ? Icons.check_circle_outline_rounded
                    : Icons.arrow_forward_rounded,
                size: 20,
              ),
              label: Text(isLast ? 'Tạo giải đấu' : 'Tiếp theo'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Select group ──────────────────────────────────────────────────────

class _Step1SelectGroup extends StatelessWidget {
  final List<GNEsportGroup> groups;
  final GNEsportGroup? selected;
  final ValueChanged<GNEsportGroup> onSelect;

  const _Step1SelectGroup({
    required this.groups,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.group_off_outlined,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Bạn chưa tham gia nhóm nào',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy tạo hoặc tham gia một nhóm trước khi tạo giải đấu',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepTitle(
            icon: Icons.group_outlined,
            title: 'Chọn nhóm',
            subtitle: 'Giải đấu sẽ thuộc về nhóm này',
          ),
          const SizedBox(height: 12),
          ...groups.map((g) {
            final isSelected = selected?.id == g.id;
            return GestureDetector(
              onTap: () => onSelect(g),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.secondary.withValues(alpha: 0.1)
                      : colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.secondary
                        : colorScheme.outline.withValues(alpha: 0.28),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.groups_2_outlined,
                      color: isSelected
                          ? colorScheme.secondary
                          : colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.groupName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${g.members.length} thành viên',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.secondary,
                        size: 22,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Step 2: Add participants ──────────────────────────────────────────────────

class _Step2AddParticipants extends StatelessWidget {
  final List<String> memberIds;
  final Map<String, MemberInfo> memberInfo;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const _Step2AddParticipants({
    required this.memberIds,
    required this.memberInfo,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _StepTitle(
            icon: Icons.people_outline,
            title: 'Thêm người chơi',
            subtitle: 'Chọn ít nhất 2 người (${selected.length} đã chọn)',
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: memberIds.length,
            itemBuilder: (context, i) {
              final id = memberIds[i];
              final info = memberInfo[id];
              final name = info?.name ?? id;
              final photoUrl = info?.photoUrl;
              final isSelected = selected.contains(id);
              return GestureDetector(
                onTap: () => onToggle(id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.secondary.withValues(alpha: 0.1)
                        : colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.secondary
                          : colorScheme.outline.withValues(alpha: 0.28),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      GNCircleAvatar(photoUrl: photoUrl, name: name, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Step 3: Mode selection ────────────────────────────────────────────────────

class _Step3ModeConfig extends StatelessWidget {
  final TournamentMode mode;
  final ValueChanged<TournamentMode> onModeChange;

  const _Step3ModeConfig({required this.mode, required this.onModeChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepTitle(
            icon: Icons.emoji_events_outlined,
            title: 'Chế độ giải đấu',
            subtitle: 'Chọn kiểu thi đấu',
          ),
          const SizedBox(height: 12),
          _ModeCard(
            mode: TournamentMode.league,
            selected: mode,
            title: 'League',
            subtitle: 'Đấu vòng tròn, mọi người gặp nhau',
            icon: Icons.table_chart_outlined,
            onTap: () => onModeChange(TournamentMode.league),
          ),
          const SizedBox(height: 8),
          _ModeCard(
            mode: TournamentMode.cup,
            selected: mode,
            title: 'Cup',
            subtitle: 'Loại trực tiếp — thua là out',
            icon: Icons.account_tree_outlined,
            onTap: () => onModeChange(TournamentMode.cup),
          ),
          const SizedBox(height: 8),
          _ModeCard(
            mode: TournamentMode.full,
            selected: mode,
            title: 'Full',
            subtitle: 'Đá bảng → knockout',
            icon: Icons.sports_soccer_outlined,
            onTap: () => onModeChange(TournamentMode.full),
          ),
        ],
      ),
    );
  }
}

// ── Step 4: Config & Preview ──────────────────────────────────────────────────

class _Step4ConfigPreview extends StatelessWidget {
  final TournamentMode mode;
  final List<String> participants;
  final Map<String, MemberInfo> memberInfo;
  // cup
  final List<String> seededOrder;
  final ValueChanged<List<String>> onSeededOrderChange;
  // full
  final int groupCount;
  final int advanceCount;
  final Map<String, int> groupAssignment;
  final List<String> knockoutSeeding;
  final ValueChanged<int> onGroupCountChange;
  final ValueChanged<int> onAdvanceCountChange;
  final ValueChanged<Map<String, int>> onGroupAssignmentChange;
  final ValueChanged<List<String>> onKnockoutSeedingChange;

  const _Step4ConfigPreview({
    required this.mode,
    required this.participants,
    required this.memberInfo,
    required this.seededOrder,
    required this.onSeededOrderChange,
    required this.groupCount,
    required this.advanceCount,
    required this.groupAssignment,
    required this.knockoutSeeding,
    required this.onGroupCountChange,
    required this.onAdvanceCountChange,
    required this.onGroupAssignmentChange,
    required this.onKnockoutSeedingChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepTitle(
            icon: Icons.tune_outlined,
            title: 'Cấu hình & Xem trước',
            subtitle: 'Tuỳ chỉnh trước khi tạo giải',
          ),
          const SizedBox(height: 12),
          if (mode == TournamentMode.league)
            _LeaguePreview(participants: participants, memberInfo: memberInfo),
          if (mode == TournamentMode.cup)
            _CupConfig(
              seededOrder: seededOrder,
              memberInfo: memberInfo,
              onOrderChange: onSeededOrderChange,
            ),
          if (mode == TournamentMode.full)
            _FullStep4(
              participants: participants,
              memberInfo: memberInfo,
              groupCount: groupCount,
              advanceCount: advanceCount,
              groupAssignment: groupAssignment,
              knockoutSeeding: knockoutSeeding,
              onGroupCountChange: onGroupCountChange,
              onAdvanceCountChange: onAdvanceCountChange,
              onGroupAssignmentChange: onGroupAssignmentChange,
              onKnockoutSeedingChange: onKnockoutSeedingChange,
            ),
        ],
      ),
    );
  }
}

class _LeaguePreview extends StatelessWidget {
  final List<String> participants;
  final Map<String, MemberInfo> memberInfo;

  const _LeaguePreview({required this.participants, required this.memberInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${participants.length} người tham gia',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...participants.map((id) {
          final info = memberInfo[id];
          final name = info?.name ?? id;
          final photoUrl = info?.photoUrl;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                GNCircleAvatar(photoUrl: photoUrl, name: name, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _FullStep4 extends StatelessWidget {
  final List<String> participants;
  final Map<String, MemberInfo> memberInfo;
  final int groupCount;
  final int advanceCount;
  final Map<String, int> groupAssignment;
  final List<String> knockoutSeeding;
  final ValueChanged<int> onGroupCountChange;
  final ValueChanged<int> onAdvanceCountChange;
  final ValueChanged<Map<String, int>> onGroupAssignmentChange;
  final ValueChanged<List<String>> onKnockoutSeedingChange;

  const _FullStep4({
    required this.participants,
    required this.memberInfo,
    required this.groupCount,
    required this.advanceCount,
    required this.groupAssignment,
    required this.knockoutSeeding,
    required this.onGroupCountChange,
    required this.onAdvanceCountChange,
    required this.onGroupAssignmentChange,
    required this.onKnockoutSeedingChange,
  });

  String _groupLabel(int index) =>
      String.fromCharCode('A'.codeUnitAt(0) + index);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: bracket config
        _FullConfig(
          participantCount: participants.length,
          groupCount: groupCount,
          advanceCount: advanceCount,
          onGroupCountChange: onGroupCountChange,
          onAdvanceCountChange: onAdvanceCountChange,
        ),
        const SizedBox(height: 16),

        // Section 2: group assignment
        Text(
          'Phân bảng đấu',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Nhấn chip bảng để chuyển nhóm',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...participants.map((id) {
          final info = memberInfo[id];
          final name = info?.name ?? id;
          final photoUrl = info?.photoUrl;
          final gIndex = groupAssignment[id] ?? 0;
          final groupColors = List.generate(
            groupCount,
            (i) => colorScheme.secondary.withValues(alpha: 0.15 + i * 0.08),
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                GNCircleAvatar(photoUrl: photoUrl, name: name, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
                GestureDetector(
                  onTap: () {
                    final updated = Map<String, int>.from(groupAssignment);
                    updated[id] = ((gIndex) + 1) % groupCount;
                    onGroupAssignmentChange(updated);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: groupColors[gIndex % groupColors.length],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'Bảng ${_groupLabel(gIndex)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),

        // Section 3: knockout seeding
        Text(
          'Thứ tự vào knockout (kéo để sắp xếp)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: knockoutSeeding.length,
          onReorder: (oldIndex, newIndex) {
            final updated = List<String>.from(knockoutSeeding);
            if (newIndex > oldIndex) newIndex--;
            final item = updated.removeAt(oldIndex);
            updated.insert(newIndex, item);
            onKnockoutSeedingChange(updated);
          },
          itemBuilder: (context, i) {
            final pos = knockoutSeeding[i];
            return Container(
              key: ValueKey('seed_${i}_$pos'),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pos,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.drag_handle,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final TournamentMode mode;
  final TournamentMode selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = mode == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.secondary.withValues(alpha: 0.1)
              : colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorScheme.secondary
                : colorScheme.outline.withValues(alpha: 0.28),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(
                  alpha: isSelected ? 0.2 : 0.1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: colorScheme.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? colorScheme.secondary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.secondary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _CupConfig extends StatelessWidget {
  final List<String> seededOrder;
  final Map<String, MemberInfo> memberInfo;
  final ValueChanged<List<String>> onOrderChange;

  const _CupConfig({
    required this.seededOrder,
    required this.memberInfo,
    required this.onOrderChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thứ tự seed (kéo để sắp xếp)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: seededOrder.length,
          onReorder: (oldIndex, newIndex) {
            final updated = List<String>.from(seededOrder);
            if (newIndex > oldIndex) newIndex--;
            final item = updated.removeAt(oldIndex);
            updated.insert(newIndex, item);
            onOrderChange(updated);
          },
          itemBuilder: (context, i) {
            final id = seededOrder[i];
            final info = memberInfo[id];
            final name = info?.name ?? id;
            final photoUrl = info?.photoUrl;
            return Container(
              key: ValueKey(id),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GNCircleAvatar(photoUrl: photoUrl, name: name, size: 28),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
                  Icon(
                    Icons.drag_handle,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FullConfig extends StatelessWidget {
  final int participantCount;
  final int groupCount;
  final int advanceCount;
  final ValueChanged<int> onGroupCountChange;
  final ValueChanged<int> onAdvanceCountChange;

  const _FullConfig({
    required this.participantCount,
    required this.groupCount,
    required this.advanceCount,
    required this.onGroupCountChange,
    required this.onAdvanceCountChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final knockoutSize = groupCount * advanceCount;
    final isValidKnockout =
        knockoutSize >= 2 && (knockoutSize & (knockoutSize - 1)) == 0;
    final perGroup = participantCount > 0
        ? (participantCount / groupCount).ceil()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cấu hình bảng',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _ConfigRow(
          label: 'Số bảng',
          options: const [1, 2, 4, 8],
          selected: groupCount,
          onSelect: onGroupCountChange,
        ),
        const SizedBox(height: 10),
        _ConfigRow(
          label: 'Số lên knockout / bảng',
          options: const [1, 2, 4],
          selected: advanceCount,
          onSelect: onAdvanceCountChange,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isValidKnockout
                ? colorScheme.secondary.withValues(alpha: 0.08)
                : colorScheme.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isValidKnockout
                  ? colorScheme.secondary.withValues(alpha: 0.3)
                  : colorScheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            isValidKnockout
                ? '$groupCount bảng × ~$perGroup người/bảng → top $advanceCount/bảng = $knockoutSize người vào knockout'
                : 'Số người vào knockout ($knockoutSize) phải là lũy thừa của 2',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isValidKnockout
                  ? colorScheme.secondary
                  : colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelect;

  const _ConfigRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        ...options.map((o) {
          final isSelected = o == selected;
          return GestureDetector(
            onTap: () => onSelect(o),
            child: Container(
              margin: const EdgeInsets.only(left: 6),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.secondary : colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.secondary
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '$o',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colorScheme.onSecondary : null,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Step 4: Info ──────────────────────────────────────────────────────────────

class _Step4Info extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final DateTime? startDate;
  final DateTime? endDate;
  final GlobalKey<CostConfigFormState> costFormKey;
  final bool isBracketMode;
  final ValueChanged<DateTime> onStartDatePicked;
  final ValueChanged<DateTime> onEndDatePicked;

  const _Step4Info({
    required this.nameController,
    required this.descController,
    required this.startDate,
    required this.endDate,
    required this.costFormKey,
    this.isBracketMode = false,
    required this.onStartDatePicked,
    required this.onEndDatePicked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepTitle(
              icon: Icons.edit_outlined,
              title: 'Thông tin giải',
              subtitle: 'Đặt tên và thời gian',
            ),
            const SizedBox(height: 12),
            _FormSectionCard(
              icon: Icons.emoji_events_outlined,
              title: 'Tên & mô tả',
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: appInputDecoration(
                      context: context,
                      hintText: 'Tên giải đấu',
                      prefixIcon: Icons.edit_outlined,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: appInputDecoration(
                      context: context,
                      hintText: 'Mô tả (tuỳ chọn)',
                      prefixIcon: Icons.description_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _FormSectionCard(
              icon: Icons.calendar_today_outlined,
              title: 'Thời gian',
              child: Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      hintText: 'Ngày bắt đầu',
                      value: startDate,
                      onPicked: onStartDatePicked,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DatePickerField(
                      hintText: 'Ngày kết thúc',
                      value: endDate,
                      onPicked: (d) {
                        if (startDate != null && d.isBefore(startDate!)) {
                          showToast('Ngày kết thúc phải sau ngày bắt đầu');
                          return;
                        }
                        onEndDatePicked(d);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            CollapsibleCostConfig(
              formKey: costFormKey,
              isBracketMode: isBracketMode,
              subtitle: 'Có thể cấu hình sau',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StepTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colorScheme.secondary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _FormSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: colorScheme.secondary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String hintText;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  const _DatePickerField({
    required this.hintText,
    required this.value,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasValue = value != null;
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
        final selected = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selected != null) onPicked(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? colorScheme.secondary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: hasValue
                  ? colorScheme.secondary
                  : colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasValue ? DateFormat('dd/MM/yy').format(value!) : hintText,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasValue
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
            if (hasValue)
              Icon(
                Icons.check_circle_outline,
                size: 15,
                color: colorScheme.secondary,
              ),
          ],
        ),
      ),
    );
  }
}
