import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_frontend/screens/sked_screen/skeds_dialogs.dart';
import 'package:provider/provider.dart';

import '../../models/Sked.dart';
import '../../models/Department.dart';
import '../../models/Employee.dart';
import '../../providers/DepartmentProvider.dart';
import '../../providers/EmployeeProvider.dart';
import '../../providers/SkedProvider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:inventory_frontend/models/Sked.dart';
import 'package:inventory_frontend/models/Department.dart';
import 'package:inventory_frontend/models/Employee.dart';
import 'package:inventory_frontend/providers/SkedProvider.dart';
import 'package:inventory_frontend/providers/DepartmentProvider.dart';
import 'package:inventory_frontend/providers/EmployeeProvider.dart';
import 'package:inventory_frontend/screens/sked_screen/skeds_dialogs.dart';

DataCell _buildDataCell(String text, double width, int maxLines, bool isMoved, bool isWrittenOff) {
  return DataCell(
    Container(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: isWrittenOff
              ? Colors.red
              : isMoved ? Colors.orange : null,
          decoration: isWrittenOff ? TextDecoration.lineThrough : null,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: maxLines,
        textAlign: TextAlign.center,
        softWrap: true,
      ),
    ),
  );
}

DataCell _buildAvailabilityCell(BuildContext context, Sked sked, DateTime? selectedDate) {
  final provider = Provider.of<SkedProvider>(context, listen: false);

  return DataCell(
    StatefulBuilder(
      builder: (context, setState) {
        return Checkbox(
          value: sked.available,
          onChanged: selectedDate != null ? (val) async {
            if (val == null) return;

            // Локальное мгновенное обновление
            setState(() {
              sked.available = val;
            });

            try {
              // Асинхронное обновление на сервере
              await provider.updateSked(sked.copyWith(available: val));
            } catch (e) {
              // Откат при ошибке
              setState(() {
                sked.available = !val;
              });
              debugPrint('Ошибка обновления: $e');
            }
          } : null,
        );
      },
    ),
  );
}

List<DataRow> buildTableRows({
  required BuildContext context,
  required List<Sked> skeds,
  required DepartmentProvider departmentProvider,
  required EmployeeProvider employeeProvider,
  required DateTime? selectedDate,
}) {
  final dateFormat = DateFormat('dd.MM.yyyy');

  return skeds.asMap().entries.map((entry) {
    final sked = entry.value;
    final rowNumber = entry.key + 1;
    final isMoved = sked.comments.contains('Перемещено в');
    final isWrittenOff = sked.isWrittenOff || (sked.comments?.contains('Списано') ?? false);

    final department = departmentProvider.departments.firstWhere(
          (d) => d.id == sked.departmentId,
      orElse: () => Department(id: 0, name: 'Неизвестно'),
    );

    final employee = employeeProvider.employees.firstWhere(
          (e) => e.id == sked.employeeId,
      orElse: () => Employee(id: 0, name: 'Неизвестно'),
    );

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (isWrittenOff) {
            return Colors.red.withOpacity(0.3);
          } else if (isMoved) {
            return Colors.orange.withOpacity(0.2);
          }
          return null;
        },
      ),
      cells: [
        _buildDataCell(rowNumber.toString(), 12, 1, isMoved, isWrittenOff),
        _buildDataCell(sked.assetCategory, 50, 1, isMoved, isWrittenOff),
        _buildDataCell(dateFormat.format(sked.dateReceived), 55, 1, isMoved, isWrittenOff),
        _buildDataCell(sked.skedNumber, 55, 1, isMoved, isWrittenOff),
        _buildDataCell(sked.itemName, 150, 4, isMoved, isWrittenOff),
        _buildDataCell(sked.serialNumber, 80, 1, isMoved, isWrittenOff),
        _buildDataCell(sked.count.toString(), 20, 1, isMoved, isWrittenOff),
        _buildDataCell(sked.measure, 20, 1, isMoved, isWrittenOff),
        _buildDataCell(sked.price.toString(), 60, 1, isMoved, isWrittenOff),
        _buildDataCell(sked.place.toString(), 70, 1, isMoved, isWrittenOff),
        _buildDataCell(employee.name, 80, 1, isMoved, isWrittenOff),
        _buildDataCell(sked.comments, 100, 3, isMoved, isWrittenOff),
        _buildAvailabilityCell(context, sked, selectedDate),
        _buildActionsCell(context, sked, department, employee, isWrittenOff),
      ],
    );
  }).toList();
}

DataCell _buildActionsCell(
    BuildContext context,
    Sked sked,
    Department department,
    Employee employee,
    bool isWrittenOff,
    ) {
  final provider = Provider.of<SkedProvider>(context, listen: false);

  return DataCell(
    Container(
      width: isWrittenOff ? 40 : 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: isWrittenOff
            ? [
          IconButton(
            icon: Icon(Icons.assignment, size: 14),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () => showWriteOffDetailsDialog(context, sked),
          ),
        ]
            : [
          IconButton(
            icon: Icon(Icons.edit, size: 14),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () => showEditSkedDialog(context, sked),
          ),
          IconButton(
            icon: Icon(Icons.move_to_inbox, size: 14),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () => showMoveSkedDialog(context, sked),
          ),
          IconButton(
            icon: Icon(Icons.money_off, size: 14, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () => showWriteOffDialog(context, sked.id),
          ),
          IconButton(
            icon: Icon(Icons.delete, size: 14),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Удалить запись?'),
                  content: Text('Вы уверены, что хотите удалить ${sked.itemName}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Нет'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Да'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await provider.deleteSked(sked.id);
              }
            },
          ),
        ],
      ),
    ),
  );
}