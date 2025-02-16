import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:startup_app/data/images/images_repository.dart';
import 'package:startup_app/data/repositories/location/location_repository.dart';
import 'package:startup_app/data/repositories/user/user_repository.dart';
import 'package:startup_app/utils/ui/loader.dart';
import '../../../../data/repositories/offers/offers_repository.dart';
import '../../../../data/repositories/posts/posts_repository.dart';
import '../../../../helpers/network_manager.dart';
import '../../../personalization/models/offer_model.dart';
import '../../../personalization/models/post_model.dart';
import '../images/image_controller.dart';


/// --- Posting Controller --- ///
class PostingController extends GetxController {
  static PostingController get instance => Get.find();

  final title = TextEditingController();
  final description = TextEditingController();
  final category = ''.obs;
  GlobalKey<FormState> postKey = GlobalKey<FormState>();

  final ImageController imageController = Get.find<ImageController>();

  /// Add Post
  Future<void> addPost() async {
    final PostsRepository postsRepository = Get.put(PostsRepository());
    final ImagesRepository imagesRepository = Get.put(ImagesRepository());
    final LocationRepository locationRepository = Get.put(LocationRepository());
    final UserRepository userRepository = Get.put(UserRepository());
    final user = await userRepository.getCurrentUser();
    final userModel = await userRepository.getCurrentUserModel(); // Get all info of user including username

    /// Check for user
    if (user == null || userModel ==null ) {
      TLoader.errorSnackBar(title: "User not logged in", message: "Please log in to post an offer."); // todo change it so once you click the add button you immediantly go to the login
      return;
    }


    try {
      /// Check if internet is connected
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoader.errorSnackBar(title: "No Internet", message: "Please check your internet connection.");
        return;
      }

      /// Check if form is valid (Not sure how to implement fully)
      if (postKey.currentState == null || !postKey.currentState!.validate()) {
        debugPrint("Form is not valid");
        TLoader.errorSnackBar(title: "Validation Error", message: "Please fill out all fields correctly.");
        return;
      }

      /// Convert RxList<XFile?> to List<XFile>
      List<XFile> images = imageController.images.where((image) => image != null).cast<XFile>().toList();

      /// Get image urls after uploading
      List<String> imageUrls = await imagesRepository.uploadPostImages(images, user.uid);

      /// Get user's position
      final position = await locationRepository.determinePosition();
      if (position == null) return; // Don't post unless they give their position

      /// Create post model
      final post = PostModel(
        userId: user.uid,
        userName: userModel.username,
        title: title.text,
        description: description.text,
        category: category.value,
        imageUrls: imageUrls,
        timestamp: Timestamp.now(),
        location: GeoPoint(position.latitude, position.longitude),
        status: 'Posted',
        chatId: ''
      );

      /// Add Post
      await postsRepository.addPost(post, user.uid);

      Get.back();

      /// Clear everything (Haven't finished doing the images)
      clearForm();
    } catch (e) {
      TLoader.errorSnackBar(title: "Oh Snap!", message: e.toString());
    }
  }

  /// Add Offer
  Future<void> addOffer(String postID, String titleOfPost, String userOfPost, String userOfPostId) async {
    final OffersRepository offersRepository = Get.put(OffersRepository());
    final UserRepository userRepository = Get.put(UserRepository());
    final ImagesRepository imagesRepository = Get.put(ImagesRepository());
    final LocationRepository locationRepository = Get.put(LocationRepository());

    try {

      final user = await userRepository.getCurrentUser();
      final userModel = await userRepository.getCurrentUserModel(); // TODO make get current user model to be in a more dedicated repository

      /// Check for user
      if (user == null || userModel == null) {
        TLoader.errorSnackBar(title: "User not logged in",
            message: "Please log in to post an offer."); // todo change it so once you click the add button you immediantly go to the login
        return;
      }

      ///Check if internet is connected
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoader.errorSnackBar(title: "No Internet",
            message: "Please check your internet connection.");
        return;
      }

      /// Check if form is valid (Not sure how to correctly implement it)
      if (postKey.currentState == null || !postKey.currentState!.validate()) {
        debugPrint("Form is not valid");
        TLoader.errorSnackBar(title: "Validation Error",
            message: "Please fill out all fields correctly.");
        return;
      }

      /// Convert RxList<XFile?> to List<XFile>
      List<XFile> images = imageController.images.where((image) =>
      image != null).cast<XFile>().toList();

      /// Get image urls
      List<String> imageUrls = await imagesRepository.uploadOfferImages(
          images, user.uid, postID);

      /// Get user's position
      final position = await locationRepository.determinePosition();
      if (position == null) {
        return; // Don't post unless they give their position
      }

      /// Create offer model
      final offer = OfferModel(
          userId: user.uid,
          userName: userModel.username,
          title: title.text,
          description: description.text,
          category: category.value,
          imageUrls: imageUrls,
          timestamp: Timestamp.now(),
          location: GeoPoint(position.latitude, position.longitude),
          status: "Offered",
          postId: postID,
          titleOfPost: titleOfPost,
          userOfPost: userOfPost,
          userOfPostId: userOfPostId

      );

      /// Add Offer
      await offersRepository.addOffer(postID, offer, user.uid);

      Get.back();

      /// Clear everything
      clearForm();
    } catch (e) {
      TLoader.errorSnackBar(title: "Oh Snap!", message: e.toString());
    }
  }

  /// Function to accept an offer
  Future<void> acceptOffer (String postId, String offerId, String offerUserId, String postUserId) async { // put in posts or offers repository
    final OffersRepository offersRepository = Get.put(OffersRepository());
    final PostsRepository postsRepository = Get.put(PostsRepository());

    try {
      /// Retrieve the offer and post for accepting the offer
      List<Future<DocumentSnapshot>> futures = [
        offersRepository.retrieveOffer(offerId),
        postsRepository.retrievePost(postId),
      ];

      /// Retrieve the document snapshots
      List<DocumentSnapshot> results = await Future.wait(futures);

      DocumentSnapshot offerDoc = results[0];
      DocumentSnapshot postDoc = results[1];

      /// If offer and post exists
      if (offerDoc.exists && postDoc.exists) {
        Map<String, dynamic> dataOffer = offerDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> dataPost = postDoc.data() as Map<String, dynamic>;
        if (dataOffer['UserId'] == offerUserId && dataPost['UserId'] == postUserId) {
          List<Future<void>> futures = [
            offersRepository.updateOffer(offerId, 'Accepted'),
            postsRepository.updatePost(postId, 'Accepted'),
          ];
          await Future.wait(futures);
        }
      }
    } catch (e) {
      TLoader.errorSnackBar(title: "Oh Snap!", message: e.toString());
    }
  }

  /// Function to accept an offer
  Future<void> denyOffer (String postId, String offerId, String offerUserId) async { // put in posts or offers repository
    final OffersRepository offersRepository = Get.put(OffersRepository());
    try {
      DocumentSnapshot offerDoc = await offersRepository.retrieveOffer(offerId);
      if (offerDoc.exists) { // If offer exists
        Map<String, dynamic> data = offerDoc.data() as Map<String, dynamic>;
        if (data['UserId'] == offerUserId) {
          await offersRepository.updateOffer(offerId, 'Denied');
        }
      }
    } catch (e) {
      TLoader.errorSnackBar(title: "Oh Snap!", message: e.toString());
    }
  }

  /// Clear form
  void clearForm() {
    title.clear();
    description.clear();
    category.value = '';
    imageController.clearImages();
    // imageController.clearImages(); // Ensure ImageController has this method to clear images
  }

  @override
  void onClose() {
    clearForm(); // Clear everything when the controller is closed
    super.onClose();
  }


}

