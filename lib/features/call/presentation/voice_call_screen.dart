import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/call_repository.dart';

class VoiceCallScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String partnerName;
  final String? partnerAvatarUrl;

  const VoiceCallScreen({
    super.key,
    required this.matchId,
    required this.partnerName,
    this.partnerAvatarUrl,
  });

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  late RtcEngine _engine;
  bool _muted = false;
  bool _speakerOn = true;
  bool _joined = false;
  bool _loading = true;
  String _statusText = '获取通话凭证...';
  int _duration = 0;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initAgora();
  }

  Future<void> _initAgora() async {
    await Permission.microphone.request();

    try {
      // 发送通话邀请推送给对方
      final callRepo = ref.read(callRepositoryProvider);
      try {
        await callRepo.sendInvite(widget.matchId);
      } catch (_) {
        // 通话邀请推送失败不阻塞，对方可能仍能接听
      }

      // 从后端获取 Agora token
      final data = await callRepo.getAgoraToken(widget.matchId);
      final token = data['token'] as String;
      final appId = data['appId'] as String;
      final uid = (data['uid'] as num).toInt();

      if (!mounted) return;
      setState(() => _statusText = '连接中...');

      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(appId: appId));

      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) {
            setState(() {
              _joined = true;
              _loading = false;
              _statusText = '等待对方接听...';
            });
          }
        },
        onUserJoined: (_, __, ___) {
          if (mounted) {
            setState(() => _statusText = '通话中');
            // 对方加入后才开始计时
            Stream.periodic(const Duration(seconds: 1)).listen((_) {
              if (mounted && _joined) setState(() => _duration++);
            });
          }
        },
        onUserOffline: (_, __, ___) => _hangUp(),
        onLeaveChannel: (_, __) {},
      ));

      await _engine.enableAudio();
      await _engine.setEnableSpeakerphone(true);
      await _engine.setChannelProfile(
          ChannelProfileType.channelProfileCommunication);
      await _engine.joinChannel(
        token: token,
        channelId: widget.matchId,
        uid: uid,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _statusText = '连接失败，请重试');
        Future.delayed(const Duration(seconds: 2), _hangUp);
      }
    }
  }

  String get _durationText {
    final m = _duration ~/ 60;
    final s = _duration % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _hangUp() async {
    _pulseCtrl.stop();
    await _engine.leaveChannel();
    await _engine.release();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    await _engine.muteLocalAudioStream(_muted);
    HapticFeedback.lightImpact();
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _speakerOn = !_speakerOn);
    await _engine.setEnableSpeakerphone(_speakerOn);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _engine.leaveChannel();
    _engine.release();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 模糊背景
          widget.partnerAvatarUrl?.isNotEmpty == true
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: CachedNetworkImage(
                    imageUrl: widget.partnerAvatarUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    errorWidget: (_, __, ___) => _GradientBackground(),
                  ),
                )
              : _GradientBackground(),

          Container(color: Colors.black.withValues(alpha: 0.5)),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white70, size: 30),
                    onPressed: _hangUp,
                  ),
                ),

                const Spacer(flex: 2),

                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: _joined ? 1.0 : _pulse.value,
                    child: child,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4D88).withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 62,
                      backgroundImage: widget.partnerAvatarUrl != null &&
                              widget.partnerAvatarUrl!.isNotEmpty
                          ? ResizeImage(
                              CachedNetworkImageProvider(widget.partnerAvatarUrl!),
                              width: 200,
                            )
                          : null,
                      backgroundColor: const Color(0xFFFF4D88),
                      child: widget.partnerAvatarUrl == null ||
                              widget.partnerAvatarUrl!.isEmpty
                          ? Text(
                              widget.partnerName.isNotEmpty
                                  ? widget.partnerName[0]
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 48,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            )
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(widget.partnerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700)),

                const SizedBox(height: 8),

                Text(
                  _joined ? _durationText : _statusText,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75), fontSize: 16),
                ),

                const Spacer(flex: 3),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundButton(
                        icon: _muted ? Icons.mic_off : Icons.mic,
                        label: _muted ? '取消静音' : '静音',
                        active: _muted,
                        onTap: _toggleMute,
                      ),
                      _HangupButton(onTap: _hangUp),
                      _RoundButton(
                        icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                        label: _speakerOn ? '扬声器' : '听筒',
                        active: !_speakerOn,
                        onTap: _toggleSpeaker,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B0F6B), Color(0xFF1A0A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: active ? const Color(0xFFFF4D88) : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _HangupButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HangupButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.red.shade500,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 8),
          const Text('挂断',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
