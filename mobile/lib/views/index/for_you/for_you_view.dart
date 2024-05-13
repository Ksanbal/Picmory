import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:picmory/common/components/get_shimmer.dart';
import 'package:picmory/common/components/page_indicator_widget.dart';
import 'package:picmory/common/families/color_family.dart';
import 'package:picmory/common/families/text_styles/caption_sm_style.dart';
import 'package:picmory/common/families/text_styles/text_sm_style.dart';
import 'package:picmory/viewmodels/index/for_you/for_you_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:solar_icons/solar_icons.dart';

class ForYouView extends StatelessWidget {
  const ForYouView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ForYouViewmodel>(context, listen: true);

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            controller: vm.forYouViewController,
            padding: EdgeInsets.only(
              top: 64 + MediaQuery.of(context).padding.top,
              bottom: MediaQuery.of(context).padding.bottom + 110,
            ),
            children: [
              // 좋아요
              SizedBox(
                height: MediaQuery.of(context).size.width - 32,
                child: PageView.builder(
                  itemCount: 6,
                  controller: vm.likePageController,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1 / 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: index % 2 == 0 ? Colors.grey : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PageIndicatorWidget(
                      controller: vm.likePageController,
                      count: 6,
                    ),
                    InkWell(
                      onTap: () {},
                      child: const Row(
                        children: [
                          Text(
                            "좋아요 더보기",
                            style: TextSmStyle(
                              color: ColorFamily.textGrey600,
                            ),
                          ),
                          Icon(
                            SolarIconsOutline.altArrowRight,
                            color: ColorFamily.textGrey600,
                            size: 20,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              // 앨범
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 16,
                  childAspectRatio: 160 / 206,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: vm.albums.isEmpty ? 10 : vm.albums.length,
                itemBuilder: (context, index) {
                  if (vm.albums.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: AspectRatio(
                            aspectRatio: 1 / 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: getShimmer(index),
                            ),
                          ),
                        ),
                        const Text(
                          "-",
                          style: TextSmStyle(),
                        ),
                        const Text(
                          "-",
                          style: CaptionSmStyle(
                            color: ColorFamily.disabledGrey500,
                          ),
                        )
                      ],
                    );
                  }

                  final album = vm.albums[index];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: AspectRatio(
                          aspectRatio: 1 / 1,
                          child: InkWell(
                            onTap: () {},
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: ExtendedImage.network(
                                album.imageUrls.first,
                                fit: BoxFit.cover,
                                loadStateChanged: (state) {
                                  if (state.extendedImageLoadState == LoadState.loading) {
                                    return getShimmer(index);
                                  }
                                  if (state.extendedImageLoadState == LoadState.failed) {
                                    return const Center(
                                      child: Icon(Icons.error),
                                    );
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        album.name,
                        style: const TextSmStyle(),
                      ),
                      Text(
                        album.imageUrls.length.toString(),
                        style: const CaptionSmStyle(
                          color: ColorFamily.disabledGrey500,
                        ),
                      )
                    ],
                  );
                },
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor:
                        vm.isShrink ? Colors.black.withOpacity(0.3) : Colors.transparent,
                    child: IconButton(
                      icon: const Icon(SolarIconsOutline.addFolder),
                      color: vm.isShrink ? Colors.white : Colors.black,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor:
                        vm.isShrink ? Colors.black.withOpacity(0.3) : Colors.transparent,
                    child: IconButton(
                      icon: const Icon(SolarIconsOutline.hamburgerMenu),
                      color: vm.isShrink ? Colors.white : Colors.black,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
