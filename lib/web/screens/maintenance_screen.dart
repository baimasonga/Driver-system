import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/fleet_data_provider.dart';
import '../../state/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/status_badge.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppColors.amber500,
          unselectedLabelColor: AppColors.neutral400,
          indicatorColor: AppColors.amber500,
          tabs: const [
            Tab(text: 'Work Orders'),
            Tab(text: 'Spare Parts'),
            Tab(text: 'Tyres'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [_WorkOrders(), _SparePartsTab(), _TyresTab()],
          ),
        ),
      ],
    );
  }
}

class _WorkOrders extends StatelessWidget {
  const _WorkOrders();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    if (data.maintenanceRequests.isEmpty) {
      return const Center(
        child: Text(
          'No maintenance requests.',
          style: TextStyle(color: AppColors.neutral400),
        ),
      );
    }
    return ListView.separated(
      itemCount: data.maintenanceRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final m = data.maintenanceRequests[i];
        final vehicle = data.vehicleById(m.vehicleId);
        final driver = data.driverById(m.driverId);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.neutral900,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.neutral800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${vehicle?.registrationNumber ?? m.vehicleId} · ${m.category}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  StatusBadge(label: m.status.label),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Reported by ${driver?.name ?? m.driverId} · Severity: ${m.severity}',
                style: const TextStyle(
                  color: AppColors.neutral400,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                m.description,
                style: const TextStyle(
                  color: AppColors.neutral100,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 20,
                runSpacing: 6,
                children: [
                  if (m.garageName != null) _kv('Garage', m.garageName!),
                  if (m.quotationAmount != null)
                    _kv('Quotation', formatCurrency(m.quotationAmount!)),
                  if (m.approvedAmount != null)
                    _kv('Approved', formatCurrency(m.approvedAmount!)),
                  if (m.invoiceAmount != null)
                    _kv('Invoice', formatCurrency(m.invoiceAmount!)),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _ActionsFor(request: m),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.neutral700,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.neutral100,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionsFor extends StatelessWidget {
  final MaintenanceRequest request;
  const _ActionsFor({required this.request});

  @override
  Widget build(BuildContext context) {
    final data = context.read<FleetDataProvider>();
    switch (request.status) {
      case MaintenanceStatus.pending:
        return ElevatedButton(
          onPressed: () => _promptBudget(context, data, request),
          child: const Text('Approve Budget'),
        );
      case MaintenanceStatus.approved:
        return ElevatedButton(
          onPressed: () => _promptGarage(context, data, request.id),
          child: const Text('Dispatch to Garage'),
        );
      case MaintenanceStatus.inGarage:
        return Wrap(
          spacing: 8,
          children: [
            OutlinedButton(onPressed: () => _promptPart(context, data, request), child: const Text('Register Part Swap')),
            ElevatedButton(onPressed: () => _promptCompletion(context, data, request), child: const Text('Mark Completed')),
          ],
        );
      case MaintenanceStatus.completed:
        return ElevatedButton(
          onPressed: () async {
            try {
              final name =
                  context.read<AuthProvider>().profile?.fullName ??
                  'Fleet Manager';
              await data.verifyMaintenanceRequest(request.id, verifier: name);
            } catch (e) {
              _error(context, e);
            }
          },
          child: const Text('Verify Repair'),
        );
      case MaintenanceStatus.verified:
        return const Text(
          'Closed',
          style: TextStyle(color: AppColors.neutral400, fontSize: 12),
        );
    }
  }

  void _promptBudget(
    BuildContext context,
    FleetDataProvider data,
    MaintenanceRequest request,
  ) {
    final controller = TextEditingController(
      text: '${request.quotationAmount ?? ''}',
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Maintenance Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Approved amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final amount = double.tryParse(controller.text) ?? 0;
                final name =
                    context.read<AuthProvider>().profile?.fullName ??
                    'Fleet Manager';
                await data.approveMaintenanceRequest(
                  request.id,
                  approver: name,
                  approvedAmount: amount,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                _error(context, e);
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _promptCompletion(
    BuildContext context,
    FleetDataProvider data,
    MaintenanceRequest request,
  ) {
    final controller = TextEditingController(
      text: '${request.approvedAmount ?? request.quotationAmount ?? ''}',
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete Maintenance'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Final invoice amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await data.completeMaintenanceRequest(
                  request.id,
                  completedBy: request.garageName ?? 'Garage',
                  invoiceAmount: double.tryParse(controller.text) ?? 0,
                  completionNotes: 'Repair completed and test drive passed.',
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                _error(context, e);
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _error(BuildContext context, Object error) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
  }

  void _promptPart(BuildContext context, FleetDataProvider data, MaintenanceRequest request) {
    final availableParts = data.spareParts.where((p) => p.stockQty > 0).toList();
    if (availableParts.isEmpty) {
      _error(context, StateError('Add stock to the inventory catalog first.'));
      return;
    }
    String partId = availableParts.first.id;
    final removed = TextEditingController();
    final installed = TextEditingController();
    final condition = TextEditingController(text: 'Worn');
    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Serialized Part Replacement'),
      content: StatefulBuilder(builder: (context, setState) => Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: partId,
          items: availableParts.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.partName} (${p.stockQty})'))).toList(),
          onChanged: (v) => setState(() => partId = v!), decoration: const InputDecoration(labelText: 'Catalog part')),
        const SizedBox(height: 10),
        TextField(controller: removed, decoration: const InputDecoration(labelText: 'Removed part serial number')),
        const SizedBox(height: 10),
        TextField(controller: installed, decoration: const InputDecoration(labelText: 'Installed part serial number')),
        const SizedBox(height: 10),
        TextField(controller: condition, decoration: const InputDecoration(labelText: 'Removed part condition')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async { try {
          final name = context.read<AuthProvider>().profile?.fullName ?? 'Fleet Manager';
          await data.registerPartReplacement(workOrderId: request.id, sparePartId: partId,
            removedSerial: removed.text, installedSerial: installed.text,
            removedCondition: condition.text, capturedBy: name);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        } catch (e) { _error(context, e); } }, child: const Text('Record & Issue Part'))],
    ));
  }

  void _promptGarage(BuildContext context, FleetDataProvider data, String id) {
    final controller = TextEditingController(
      text: 'Toyota Official Country Garage',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.neutral900,
        title: const Text(
          'Dispatch to Garage',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Garage name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final name =
                    context.read<AuthProvider>().profile?.fullName ??
                    'Fleet Manager';
                await data.dispatchToGarage(
                  id,
                  dispatcher: name,
                  garageName: controller.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                _error(context, e);
              }
            },
            child: const Text('Dispatch'),
          ),
        ],
      ),
    );
  }
}

class _SparePartsTab extends StatelessWidget {
  const _SparePartsTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    return Column(children: [Align(alignment: Alignment.centerRight,
      child: ElevatedButton.icon(onPressed: () => _addPart(context, data), icon: const Icon(Icons.add), label: const Text('Add Catalog Part'))),
      const SizedBox(height: 10), Expanded(child: ListView.separated(
      itemCount: data.spareParts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = data.spareParts[i];
        final low = p.stockQty <= p.reorderLevel;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.neutral900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: low
                  ? AppColors.red500.withOpacity(0.4)
                  : AppColors.neutral800,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.partName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      '${p.partNumber} · ${p.category} · ${p.compatibleVehicleModel}',
                      style: const TextStyle(
                        color: AppColors.neutral400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${p.stockQty} in stock',
                    style: TextStyle(
                      color: low ? AppColors.red500 : AppColors.neutral100,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    formatCurrency(p.unitCost),
                    style: const TextStyle(
                      color: AppColors.neutral400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ))]);
  }

  void _addPart(BuildContext context, FleetDataProvider data) {
    final name = TextEditingController(); final number = TextEditingController();
    final category = TextEditingController(); final model = TextEditingController();
    final cost = TextEditingController(); final stock = TextEditingController(); final reorder = TextEditingController();
    showDialog(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Add Inventory Part'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Part name')),
        TextField(controller: number, decoration: const InputDecoration(labelText: 'Catalog/part number')),
        TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
        TextField(controller: model, decoration: const InputDecoration(labelText: 'Compatible vehicle model')),
        TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit cost')),
        TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening stock')),
        TextField(controller: reorder, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low-stock trigger')),
      ])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async { try { await data.saveSparePart(SparePart(
          id: 'sp-${DateTime.now().microsecondsSinceEpoch}', partName: name.text.trim(), partNumber: number.text.trim(),
          category: category.text.trim(), compatibleVehicleModel: model.text.trim(), unitCost: double.tryParse(cost.text) ?? -1,
          stockQty: int.tryParse(stock.text) ?? -1, reorderLevel: int.tryParse(reorder.text) ?? -1));
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } }, child: const Text('Save'))]));
  }
}

class _TyresTab extends StatelessWidget {
  const _TyresTab();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FleetDataProvider>();
    return ListView.separated(
      itemCount: data.tyres.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final t = data.tyres[i];
        final vehicle = data.vehicleById(t.vehicleId);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.neutral900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neutral800),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle?.registrationNumber ?? t.vehicleId} · ${t.position}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      '${t.brand} ${t.size} · S/N ${t.serialNumber}',
                      style: const TextStyle(
                        color: AppColors.neutral400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: t.condition,
                color: t.condition == 'Worn'
                    ? AppColors.red500
                    : AppColors.green500,
              ),
            ],
          ),
        );
      },
    );
  }
}
