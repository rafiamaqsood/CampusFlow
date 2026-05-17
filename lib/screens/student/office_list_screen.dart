import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/office_model.dart';
import '../../services/student_service.dart';
import 'officer_list_screen.dart';

class OfficeListScreen extends StatelessWidget {
  const OfficeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Select Office', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<OfficeModel>>(
        stream: StudentService().getOffices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final offices = snapshot.data!;
          // Group by block
          final Map<String, List<OfficeModel>> groupedOffices = {};
          for (var office in offices) {
            groupedOffices.putIfAbsent(office.block, () => []).add(office);
          }

          final blocks = groupedOffices.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: blocks.length,
            itemBuilder: (context, index) {
              final block = blocks[index];
              final blockOffices = groupedOffices[block]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12, top: 12),
                    child: Text(
                      block.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.grey[600], 
                        letterSpacing: 1.2
                      ),
                    ),
                  ),
                  ...blockOffices.map((office) => _buildOfficeCard(context, office)).toList(),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOfficeCard(BuildContext context, OfficeModel office) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OfficerListScreen(office: office)),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1), 
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.business_outlined, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(office.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Text('Floor: ${office.floor}', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
                        if (office.announcement != null && office.announcement!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                Icon(Icons.campaign, size: 12, color: Colors.red[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'LIVE ALERT',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red[700]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No offices found', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
