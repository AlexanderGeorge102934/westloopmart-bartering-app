import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:startup_app/utils/ui/loader.dart';
import '../../../../data/repositories/offers/offers_repository.dart';
import '../../../../data/repositories/posts/posts_repository.dart';
import '../../../../helpers/network_manager.dart';
import '../../../personalization/models/offer_model.dart';
import '../../../personalization/models/post_model.dart';
import '../images/image_controller.dart';

class PostingController extends GetxController {
  static PostingController get instance => Get.find();

  final title = TextEditingController();
  final description = TextEditingController();
  final category = TextEditingController();
  GlobalKey<FormState> postKey = GlobalKey<FormState>();

  final ImageController imageController = Get.find<ImageController>();

  /// Add Post
  Future<void> addPost() async {
    final PostsRepository postsRepository = Get.put(PostsRepository());
    final user = await postsRepository.getCurrentUser();
    if (user == null) {
      TLoader.errorSnackBar(title: "User not logged in", message: "Please log in to post an offer."); // todo change it so once you click the add button you immediantly go to the login
      return;
    }

    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoader.errorSnackBar(title: "No Internet", message: "Please check your internet connection.");
        return;
      }

      if (postKey.currentState == null || !postKey.currentState!.validate()) {
        debugPrint("Form is not valid");
        TLoader.errorSnackBar(title: "Validation Error", message: "Please fill out all fields correctly.");
        return;
      }

      /// Convert RxList<XFile?> to List<XFile>
      List<XFile> images = imageController.images.where((image) => image != null).cast<XFile>().toList();

      /// Get image urls
      List<String> imageUrls = await postsRepository.uploadImages(images, user.uid);

      /// Get user's position
      final position = await postsRepository.determinePosition();
      if (position == null) return; // Don't post unless they give their position

      final post = PostModel(
        userId: user.uid,
        userName: user.email ?? "Anonymous", // todo figure out how to get rid of anonymous
        title: title.text,
        description: description.text,
        category: category.text,
        imageUrls: imageUrls,
        timestamp: Timestamp.now(),
        location: GeoPoint(position.latitude, position.longitude),
      );

      /// Add Post
      await postsRepository.addPost(post);

      /// Clear everything (Haven't finished doing the images)
      title.clear();
      description.clear();
      category.clear();
    } catch (e) {
      TLoader.errorSnackBar(title: "Oh Snap!", message: e.toString());
    }
  }

  /// Add Offer
  Future<void> addOffer(String postID) async {
    final OffersRepository offersRepository = Get.put(OffersRepository());
    final user = await offersRepository.getCurrentUser();
    if (user == null) {
      TLoader.errorSnackBar(title: "User not logged in", message: "Please log in to post an offer."); // todo change it so once you click the add button you immediantly go to the login
      return;
    }

    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoader.errorSnackBar(title: "No Internet", message: "Please check your internet connection.");
        return;
      }

      if (postKey.currentState == null || !postKey.currentState!.validate()) {
        debugPrint("Form is not valid");
        TLoader.errorSnackBar(title: "Validation Error", message: "Please fill out all fields correctly.");
        return;
      }

      /// Convert RxList<XFile?> to List<XFile>
      List<XFile> images = imageController.images.where((image) => image != null).cast<XFile>().toList();

      /// Get image urls
      List<String> imageUrls = await offersRepository.uploadImages(images, user.uid);

      /// Get user's position
      final position = await offersRepository.determinePosition();
      if (position == null) return; // Don't post unless they give their position

      final offer = OfferModel(
        userId: user.uid,
        userName: user.email ?? "Anonymous", // todo figure out how to get rid of anonymous
        title: title.text,
        description: description.text,
        category: category.text,
        imageUrls: imageUrls,
        timestamp: Timestamp.now(),
        location: GeoPoint(position.latitude, position.longitude),
        postId: postID
      );

      /// Add Post
      await offersRepository.addOffer(postID, offer);   ///Todo get post id from post to add into the

      /// Clear everything (Haven't finished doing the images)
      title.clear();
      description.clear();
      category.clear();
    } catch (e) {
      TLoader.errorSnackBar(title: "Oh Snap!", message: e.toString());
    }
  }


}

