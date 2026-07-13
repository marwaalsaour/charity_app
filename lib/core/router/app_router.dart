import 'package:charity_app/core/auth/user_role.dart';
import 'package:charity_app/features/auth/ui/screens/on_boarding.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/logic/login_cubit.dart';
import '../../features/auth/logic/register_cubit.dart';
import '../../features/auth/ui/screens/login_screen.dart';
import '../../features/auth/ui/screens/register_screen.dart';
import '../../features/beneficiary/ui/screens/beneficiary_home_screen.dart';
import '../../features/beneficiary/ui/screens/requests_screen.dart';
import '../../features/campaigns/data/models/community_campaign_model.dart';
import '../../features/campaigns/ui/screens/community_campaign_details_screen.dart';
import '../../features/campaigns/ui/screens/community_campaigns_screen.dart';
import '../../features/campaigns/ui/screens/field_volunteer_screen.dart';
import '../../features/donations/data/models/donation_checkout_args.dart';
import '../../features/donations/data/models/donation_model.dart';
import '../../features/donations/data/models/donation_receipt_model.dart';
import '../../features/donations/ui/screens/donate_amount_screen.dart';
import '../../features/donations/ui/screens/donation_details_screen.dart';
import '../../features/donations/ui/screens/donation_list_screen.dart';
import '../../features/donations/ui/screens/donation_receipt_screen.dart';
import '../../features/donations/ui/screens/impact_screen.dart';
import '../../features/home/ui/screens/home_screen.dart';
import '../../features/notifications/ui/screens/notifications_screen.dart';
import '../../features/profile/ui/screens/edit_profile_screen.dart';
import '../../features/profile/ui/screens/my_activities_screen.dart';
import '../../features/profile/ui/screens/my_donations_screen.dart';
import '../../features/profile/ui/screens/profile_screen.dart';
import '../../features/requests/data/repositories/request_repository.dart';
import '../../features/requests/logic/cubit/request_cubit.dart';
import '../../features/requests/ui/screens/education_request_page.dart';
import '../../features/requests/ui/screens/medical_request_page.dart';
import '../../features/requests/ui/screens/orphan_request_page.dart';
import '../../features/volunteer/ui/screens/volunteer_form_screen.dart';
import '../../main_navigation/main_navigation_screen.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.onboarding,

  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.loginDonor,
      builder: (context, state) => BlocProvider(
        create: (_) => LoginCubit(AuthRepository()),
        child: const LoginScreen(role: UserRole.donor),
      ),
    ),
    GoRoute(
      path: AppRoutes.loginBeneficiary,
      builder: (context, state) => BlocProvider(
        create: (_) => LoginCubit(AuthRepository()),
        child: const LoginScreen(role: UserRole.beneficiary),
      ),
    ),
    GoRoute(
      path: AppRoutes.registerDonor,
      builder: (context, state) => BlocProvider(
        create: (_) => RegisterCubit(AuthRepository()),
        child: const RegisterScreen(role: UserRole.donor),
      ),
    ),
    GoRoute(
      path: AppRoutes.registerBeneficiary,
      builder: (context, state) => BlocProvider(
        create: (_) => RegisterCubit(AuthRepository()),
        child: const RegisterScreen(role: UserRole.beneficiary),
      ),
    ),

    // ── Donor shell (no add button)
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigationScreen(role: UserRole.donor, child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.donorHome,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.donorNotifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.donorCampaigns,
          builder: (context, state) => const ImpactScreen(),
        ),
        GoRoute(
          path: AppRoutes.donorProfile,
          builder: (context, state) => const ProfileScreen(role: UserRole.donor),
        ),
        GoRoute(
          path: AppRoutes.volunteerForm,
          builder: (context, state) => const VolunteerFormScreen(),
        ),
        GoRoute(
          path: AppRoutes.donationsList,
          builder: (context, state) {
            final category = state.extra as DonationCategory;
            return DonationListScreen(category: category);
          },
        ),
        GoRoute(
          path: AppRoutes.donationDetails,
          builder: (context, state) {
            final donation = state.extra as DonationModel;
            return DonationDetailsScreen(donation: donation);
          },
        ),
        GoRoute(
          path: AppRoutes.donateAmount,
          builder: (context, state) {
            final args = state.extra as DonationCheckoutArgs;
            return DonateAmountScreen(args: args);
          },
        ),
        GoRoute(
          path: AppRoutes.donationReceipt,
          builder: (context, state) {
            final receipt = state.extra as DonationReceiptModel;
            return DonationReceiptScreen(receipt: receipt);
          },
        ),
        GoRoute(
          path: AppRoutes.myDonations,
          builder: (context, state) => const MyDonationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.myActivities,
          builder: (context, state) => const MyActivitiesScreen(),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.communityCampaigns,
          builder: (context, state) => const CommunityCampaignsScreen(),
        ),
        GoRoute(
          path: AppRoutes.communityCampaignDetails,
          builder: (context, state) {
            final campaign = state.extra as CommunityCampaignModel;
            return CommunityCampaignDetailsScreen(campaign: campaign);
          },
        ),
        GoRoute(
          path: AppRoutes.fieldVolunteer,
          builder: (context, state) {
            final campaign = state.extra as CommunityCampaignModel;
            return FieldVolunteerScreen(campaign: campaign);
          },
        ),
      ],
    ),

    // ── Beneficiary shell (with add button for requests)
    ShellRoute(
      builder: (context, state, child) {
        return BlocProvider(
          create: (_) => RequestCubit(RequestRepository()),
          child: MainNavigationScreen(role: UserRole.beneficiary, child: child),
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.beneficiaryHome,
          builder: (context, state) => const BeneficiaryHomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.beneficiaryNotifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.beneficiaryRequests,
          builder: (context, state) => const RequestsScreen(),
        ),
        GoRoute(
          path: AppRoutes.medicalRequest,
          builder: (context, state) => MedicalRequestPage(),
        ),
        GoRoute(
          path: AppRoutes.educationRequest,
          builder: (context, state) => EducationRequestPage(),
        ),
        GoRoute(
          path: AppRoutes.orphanRequest,
          builder: (context, state) => OrphanRequestPage(),
        ),
        GoRoute(
          path: AppRoutes.beneficiaryProfile,
          builder: (context, state) =>
              const ProfileScreen(role: UserRole.beneficiary),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (context, state) => const EditProfileScreen(),
        ),
      ],
    ),
  ],
);
