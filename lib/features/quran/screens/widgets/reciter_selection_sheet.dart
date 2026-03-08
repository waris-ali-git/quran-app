import 'package:flutter/material.dart';
import '../../models/reciter.dart';
import '../../services/audio_service.dart';

/// Reciter selection bottom sheet
class ReciterSelectionSheet extends StatefulWidget {
  const ReciterSelectionSheet({super.key});

  @override
  State<ReciterSelectionSheet> createState() => _ReciterSelectionSheetState();
}

class _ReciterSelectionSheetState extends State<ReciterSelectionSheet> {
  late Reciter _selectedReciter;

  @override
  void initState() {
    super.initState();
    _selectedReciter = QuranAudioService().selectedReciter;
  }

  @override
  Widget build(BuildContext context) {
    final audioService = QuranAudioService();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Reciter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your preferred Quran reciter',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Reciters List
          Expanded(
            child: ListView.builder(
              itemCount: audioService.availableReciters.length,
              itemBuilder: (context, index) {
                final reciter = audioService.availableReciters[index];
                final isSelected = _selectedReciter.id == reciter.id;

                return Material(
                  color: isSelected ? Colors.green[50] : Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      setState(() => _selectedReciter = reciter);
                      await audioService.setReciter(reciter);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF1B5E20),
                            child: Text(
                              reciter.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reciter.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reciter.localizedName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reciter.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Selection indicator
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF1B5E20),
                              size: 24,
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Close button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show reciter selection bottom sheet
void showReciterSelectionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ReciterSelectionSheet(),
  );
}


