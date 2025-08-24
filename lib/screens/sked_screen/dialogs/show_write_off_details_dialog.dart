import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../models/Sked.dart';

void showWriteOffDetailsDialog(BuildContext context, Sked sked) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Информация о списании'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Наименование: ${sked.itemName}'),
            Text('Инвентарный номер: ${sked.skedNumber}'),
            Divider(),
            Text('Причина списания:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(sked.comments.split('Причина:').last.trim()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть'),
          ),
        ],
      );
    },
  );
}