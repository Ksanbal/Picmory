import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:picmory/common/components/common/primary_button_comp.dart';
import 'package:picmory/common/tokens/colors_token.dart';
import 'package:picmory/common/tokens/icons_token.dart';
import 'package:picmory/common/tokens/layout_token.dart';
import 'package:picmory/common/tokens/typography_token.dart';
import 'package:table_calendar/table_calendar.dart';

class ChangeDateBottomsheet extends StatefulWidget {
  const ChangeDateBottomsheet({
    super.key,
    required this.focusedDay,
  });

  final DateTime focusedDay;

  @override
  State<ChangeDateBottomsheet> createState() => _ChangeDateBottomsheetState();
}

class _ChangeDateBottomsheetState extends State<ChangeDateBottomsheet> {
  late DateTime _selectedDay;

  @override
  void initState() {
    _selectedDay = widget.focusedDay;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        color: ColorsToken.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 안내바
          Container(
            width: 70,
            height: 4,
            decoration: BoxDecoration(
              color: ColorsToken.neutral[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 캘린더
          TableCalendar(
            currentDay: _selectedDay,
            focusedDay: _selectedDay,
            firstDay: DateTime(2017, 1, 1),
            lastDay: DateTime.now(),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rowHeight: 46,
            daysOfWeekHeight: 30,
            headerStyle: HeaderStyle(
              titleCentered: true,
              titleTextStyle: TypographyToken.textSm,
              titleTextFormatter: (date, locale) => DateFormat('yyyy.MM').format(date),
              formatButtonVisible: false,
              leftChevronIcon: IconsToken(
                color: ColorsToken.black,
              ).roundAltArrowLeftLinear,
              rightChevronIcon: IconsToken(
                color: ColorsToken.black,
              ).roundAltArrowRightLinear,
              headerPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) {
                return DateFormat.E().format(date).toUpperCase();
              },
              weekdayStyle: TypographyToken.captionSm.copyWith(
                color: ColorsToken.neutral,
              ),
              weekendStyle: TypographyToken.captionSm.copyWith(
                color: ColorsToken.neutral,
              ),
            ),
            calendarStyle: CalendarStyle(
              cellMargin: EdgeInsets.zero,
              defaultTextStyle: TypographyToken.textLg.copyWith(
                color: ColorsToken.neutral[300],
              ),
              weekendTextStyle: TypographyToken.textLg.copyWith(
                color: ColorsToken.neutral[300],
              ),
              disabledTextStyle: TypographyToken.textLg.copyWith(
                color: ColorsToken.neutral[300],
              ),
              outsideTextStyle: TypographyToken.textLg.copyWith(
                color: ColorsToken.neutral[300],
              ),
              selectedTextStyle: TypographyToken.textLg.copyWith(
                color: ColorsToken.primary[600],
              ),
              selectedDecoration: BoxDecoration(
                color: ColorsToken.primary[100],
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return Container(
                  alignment: Alignment.center,
                  decoration: isSameDay(day, widget.focusedDay)
                      ? BoxDecoration(
                          color: ColorsToken.neutral[50],
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    day.day.toString(),
                    style: TypographyToken.textLg.copyWith(
                      color: ColorsToken.black,
                    ),
                  ),
                );
              },
            ),
          ),
          // 완료 버튼
          Gap(SizeToken.ml),
          PrimaryButtonComp(
            onPressed: () => context.pop(_selectedDay),
            text: "완료",
            textStyle: TypographyToken.textSm.copyWith(
              color: ColorsToken.white,
            ),
          ),
        ],
      ),
    );
  }
}
