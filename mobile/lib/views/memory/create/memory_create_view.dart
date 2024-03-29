import 'dart:io';

import 'package:flutter/material.dart';
import 'package:picmory/viewmodels/memory/create/memory_create_viewmodel.dart';
import 'package:provider/provider.dart';

class MemoryCreateView extends StatelessWidget {
  const MemoryCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MemoryCreateViewmodel>(context, listen: false);

    vm.getDataFromExtra(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("메모리 생성"),
        actions: [
          // 생성 버튼
          TextButton(
            onPressed: () => vm.createMemory(context),
            child: const Text("생성 버튼"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              // 갤러리에서 사진 불러오기 버튼
              const Text("사진"),
              // 로드한 사진
              Consumer<MemoryCreateViewmodel>(
                builder: (_, vm, __) {
                  if (vm.isFromQR) {
                    if (vm.crawledImageUrl == null) {
                      return Container();
                    }
                    return Image.network(
                      vm.crawledImageUrl!,
                    );
                  } else {
                    if (vm.selectedImage == null) {
                      return Container();
                    }
                    return Image.file(
                      File(vm.selectedImage!.path),
                    );
                  }
                },
              ),
              // 갤러리에서 영상 불러오기 버튼
              const Text("영상"),
              // 로드한 동영상
              Consumer<MemoryCreateViewmodel>(
                builder: (_, vm, __) {
                  if (vm.isFromQR) {
                    if (vm.crawledVideoUrl == null) {
                      return Container();
                    }
                    return Text(vm.crawledVideoUrl!);
                  } else {
                    if (vm.selectedVideo == null) {
                      return Container();
                    }
                    return Text(vm.selectedVideo!.path);
                  }
                },
              ),
              // date 입력
              TextButton(
                onPressed: () => vm.showDatePicker(context),
                child: Consumer<MemoryCreateViewmodel>(
                  builder: (_, vm, __) {
                    return Text("입력 날짜 : ${vm.date.toString()}");
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
