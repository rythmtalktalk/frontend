import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class RecordingWidget extends StatelessWidget {
  const RecordingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              StreamBuilder<bool>(
                stream: provider.isRecordingStream,
                builder: (context, snapshot) {
                  final isRecording = snapshot.data ?? false;

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (isRecording) {
                            await provider.stopRecording();
                          } else {
                            await provider.startRecording();
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isRecording ? Colors.red : Colors.red[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRecording ? Icons.stop : Icons.mic,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isRecording ? '녹음 중... 탭해서 중지' : '탭해서 녹음 시작',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (provider.currentUserActivity?.recordingUrl != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await provider.playRecording();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('재생'),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
