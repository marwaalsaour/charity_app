class AppRoutes {
  static const onboarding = '/onboarding';
  static const loginDonor = '/login/donor';
  static const loginBeneficiary = '/login/beneficiary';
  static const registerDonor = '/register/donor';
  static const registerBeneficiary = '/register/beneficiary';

  // Donor routes
  static const donorHome = '/donor/home';
  static const donorNotifications = '/donor/notifications';
  static const donorCampaigns = '/donor/campaigns';
  static const donorProfile = '/donor/profile';
  static const volunteerForm = '/donor/volunteer';

  // Beneficiary routes
  static const beneficiaryHome = '/beneficiary/home';
  static const beneficiaryNotifications = '/beneficiary/notifications';
  static const beneficiaryRequests = '/beneficiary/requests';
  static const beneficiaryProfile = '/beneficiary/profile';
  static const medicalRequest = '/beneficiary/requests/medical';
  static const educationRequest = '/beneficiary/requests/education';
  static const orphanRequest = '/beneficiary/requests/orphan';

  // Shared detail routes
  static const donationsList = '/donations_list';
  static const donationDetails = '/donation_details';
  static const donateAmount = '/donate_amount';
  static const donationReceipt = '/donation_receipt';
  static const myDonations = '/my_donations';
  static const myActivities = '/my_activities';
  static const editProfile = '/edit_profile';
  static const communityCampaigns = '/community_campaigns';
  static const communityCampaignDetails = '/community_campaign_details';
  static const fieldVolunteer = '/field_volunteer';
}
