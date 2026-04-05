import '../../../shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import '../providers/discover_provider.dart';

/// 筛选底部弹窗
class FilterBottomSheet extends StatefulWidget {
  final DiscoverFilter initialFilter;
  final ValueChanged<DiscoverFilter> onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _ageRange;
  late double _maxDistance;
  late String _gender;

  static const _genderOptions = [
    {'label': '所有人', 'value': ''},
    {'label': '男', 'value': 'male'},
    {'label': '女', 'value': 'female'},
  ];

  @override
  void initState() {
    super.initState();
    _ageRange = RangeValues(
      widget.initialFilter.minAge.toDouble(),
      widget.initialFilter.maxAge.toDouble(),
    );
    _maxDistance = widget.initialFilter.maxDistance;
    _gender = widget.initialFilter.gender;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽指示条
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('筛选',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _ageRange = const RangeValues(18, 60);
                    _maxDistance = 50;
                    _gender = '';
                  });
                },
                child: const Text('重置',
                    style: TextStyle(
                        color: Dt.pink,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 年龄范围
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('年龄范围',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface)),
              Text('${_ageRange.start.round()} - ${_ageRange.end.round()}岁',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Dt.pink)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Dt.pink,
              inactiveTrackColor: Dt.pink.withValues(alpha: 0.25),
              thumbColor: Dt.pink,
              overlayColor: Dt.pink.withValues(alpha: 0.1),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 10),
            ),
            child: RangeSlider(
              values: _ageRange,
              min: 18,
              max: 60,
              divisions: 42,
              onChanged: (values) => setState(() => _ageRange = values),
            ),
          ),
          const SizedBox(height: 16),

          // 距离范围
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('距离范围',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface)),
              Text('${_maxDistance.round()}km',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Dt.pink)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Dt.pink,
              inactiveTrackColor: Dt.pink.withValues(alpha: 0.25),
              thumbColor: Dt.pink,
              overlayColor: Dt.pink.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _maxDistance,
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (v) => setState(() => _maxDistance = v),
            ),
          ),
          const SizedBox(height: 16),

          // 性别筛选
          Text('性别',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _genderOptions.map((option) {
              final selected = _gender == option['value'];
              return ChoiceChip(
                label: Text(option['label']!),
                selected: selected,
                selectedColor: Dt.pink,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide.none,
                onSelected: (_) => setState(() => _gender = option['value']!),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // 应用按钮
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Dt.pink, Dt.orange],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Dt.pink.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(DiscoverFilter(
                    minAge: _ageRange.start.round(),
                    maxAge: _ageRange.end.round(),
                    maxDistance: _maxDistance,
                    gender: _gender,
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                ),
                child: const Text('应用筛选',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
