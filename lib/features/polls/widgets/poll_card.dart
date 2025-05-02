import 'package:flutter/material.dart';
import '../../../core/models/poll_model.dart';

class PollCard extends StatelessWidget {
  final PollModel poll;
  final VoidCallback onTap;
  final bool showControls;
  final VoidCallback? onClosePoll;
  final VoidCallback? onReopenPoll;
  final VoidCallback? onDeletePoll;

  const PollCard({
    Key? key,
    required this.poll,
    required this.onTap,
    this.showControls = false,
    this.onClosePoll,
    this.onReopenPoll,
    this.onDeletePoll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color:
                          poll.isActive
                              ? poll.hasExpired
                                  ? Colors.orange
                                  : Colors.green
                              : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Poll title
                  Expanded(
                    child: Text(
                      poll.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Poll type indicator
                  _buildPollTypeIndicator(),
                ],
              ),
              const SizedBox(height: 8),
              // Poll description
              Text(
                poll.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Poll metadata
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    poll.creatorName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${(poll.expiresAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              // Response count
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${poll.responseCount} responses',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Tags
              if (poll.tags != null && poll.tags!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children:
                        poll.tags!.map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.blue,
                          );
                        }).toList(),
                  ),
                ),
              // Control buttons for the poll owner
              if (showControls) _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPollTypeIndicator() {
    IconData icon;
    Color color;

    if (poll.isPublic) {
      icon = Icons.public;
      color = Colors.green;
    } else if (poll.isAnonymous) {
      icon = Icons.visibility_off;
      color = Colors.purple;
    } else {
      icon = Icons.school;
      color = Colors.blue;
    }

    return Icon(icon, size: 20, color: color);
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Close/reopen poll button
          if (poll.isActive && !poll.hasExpired && onClosePoll != null)
            IconButton(
              icon: const Icon(
                Icons.pause_circle_outline,
                color: Colors.orange,
              ),
              onPressed: onClosePoll,
              tooltip: 'Close Poll',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          if (!poll.isActive && !poll.hasExpired && onReopenPoll != null)
            IconButton(
              icon: const Icon(Icons.play_circle_outline, color: Colors.green),
              onPressed: onReopenPoll,
              tooltip: 'Reopen Poll',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          // Delete poll button
          if (onDeletePoll != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDeletePoll,
              tooltip: 'Delete Poll',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
        ],
      ),
    );
  }
}
