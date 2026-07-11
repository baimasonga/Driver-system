import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/fleet_data_provider.dart';

Future<void> showDriverFormDialog(
  BuildContext context, [
  Driver? existing,
]) async {
  final data = context.read<FleetDataProvider>();
  final key = GlobalKey<FormState>();
  final staff = TextEditingController(text: existing?.staffNumber);
  final name = TextEditingController(text: existing?.name);
  final phone = TextEditingController(text: existing?.phone);
  final email = TextEditingController(text: existing?.email);
  final licence = TextEditingController(text: existing?.licenseNumber);
  final licenceClass = TextEditingController(
    text: existing?.licenseClass ?? 'Class B',
  );
  final expiry = TextEditingController(
    text: existing?.licenseExpiry ?? '${DateTime.now().year + 1}-12-31',
  );
  final photo = TextEditingController(text: existing?.photoUrl ?? '');
  DriverStatus status = existing?.status ?? DriverStatus.active;
  bool saving = false;
  String? error;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? 'Add Driver' : 'Edit Driver'),
        content: SizedBox(
          width: 620,
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _row(
                    _field(staff, 'Staff number'),
                    _field(name, 'Full name'),
                  ),
                  _row(
                    _field(phone, 'Phone'),
                    _field(email, 'Email', email: true),
                  ),
                  _row(
                    _field(licence, 'Licence number'),
                    _field(licenceClass, 'Licence class'),
                  ),
                  _row(
                    _field(expiry, 'Licence expiry (YYYY-MM-DD)'),
                    DropdownButtonFormField<DriverStatus>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: DriverStatus.values
                          .map(
                            (x) => DropdownMenuItem(
                              value: x,
                              child: Text(x.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => status = v!),
                    ),
                  ),
                  _field(photo, 'Photo URL (optional)', required: false),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: saving
                ? null
                : () async {
                    if (!key.currentState!.validate()) return;
                    if (DateTime.tryParse(expiry.text.trim()) == null) {
                      setState(
                        () => error = 'Enter the licence expiry as YYYY-MM-DD.',
                      );
                      return;
                    }
                    setState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      await data.saveDriver(
                        Driver(
                          id:
                              existing?.id ??
                              'd-${DateTime.now().microsecondsSinceEpoch}',
                          staffNumber: staff.text.trim().toUpperCase(),
                          name: name.text.trim(),
                          phone: phone.text.trim(),
                          email: email.text.trim().toLowerCase(),
                          photoUrl: photo.text.trim(),
                          licenseNumber: licence.text.trim().toUpperCase(),
                          licenseClass: licenceClass.text.trim(),
                          licenseExpiry: expiry.text.trim(),
                          status: status,
                          performanceScore: existing?.performanceScore ?? 100,
                          riskScore: existing?.riskScore ?? 0,
                        ),
                        updatedBy: 'Fleet Manager',
                      );
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      setState(() {
                        saving = false;
                        error = e.toString().replaceFirst('Bad state: ', '');
                      });
                    }
                  },
            child: Text(saving ? 'Saving…' : 'Save Driver'),
          ),
        ],
      ),
    ),
  );
}

Widget _field(
  TextEditingController c,
  String label, {
  bool email = false,
  bool required = true,
}) => TextFormField(
  controller: c,
  decoration: InputDecoration(labelText: label),
  keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
  validator: (v) {
    if (required && (v == null || v.trim().isEmpty)) return 'Required';
    if (email && v != null && (!v.contains('@') || !v.contains('.')))
      return 'Invalid email';
    return null;
  },
);
Widget _row(Widget a, Widget b) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(
    children: [
      Expanded(child: a),
      const SizedBox(width: 12),
      Expanded(child: b),
    ],
  ),
);
