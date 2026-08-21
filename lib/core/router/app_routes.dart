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
  static const donorContactUs = '/donor/contact-us';
  static const donorAbout = '/donor/about';
  static const donorTransparency = '/donor/transparency';

  // Beneficiary routes
  static const beneficiaryHome = '/beneficiary/home';
  static const beneficiaryNotifications = '/beneficiary/notifications';
  static const beneficiaryRequests = '/beneficiary/requests';
  static const beneficiaryProfile = '/beneficiary/profile';
  static const medicalRequest = '/beneficiary/requests/medical';
  static const educationRequest = '/beneficiary/requests/education';
  static const orphanRequest = '/beneficiary/requests/orphan';
  static const beneficiaryContactUs = '/beneficiary/contact-us';
  static const beneficiaryHowToGetHelp = '/beneficiary/how-to-get-help';
  static const beneficiaryAbout = '/beneficiary/about';
  static const beneficiaryTransparency = '/beneficiary/transparency';
  static const beneficiaryVolunteer = '/beneficiary/volunteer';
  static const beneficiaryAssociationMap = '/beneficiary/association-map';

  // Shared detail routes
  static const donationsList = '/donations_list';
  static const donationDetails = '/donation_details';
  static const donateAmount = '/donate_amount';
  static const donationReceipt = '/donation_receipt';
  static const myDonations = '/my_donations';
  static const mySponsorships = '/my_sponsorships';
  static const myActivities = '/my_activities';
  static const editProfile = '/edit_profile';
  static const communityCampaigns = '/community_campaigns';
  static const communityCampaignDetails = '/community_campaign_details';
  static const fieldVolunteer = '/field_volunteer';
  static const associationMap = '/association-map';

  static bool isBeneficiaryPath(String path) => path.startsWith('/beneficiary');

  static String homeForPath(String path) =>
      isBeneficiaryPath(path) ? beneficiaryHome : donorHome;

  static String contactForPath(String path) =>
      isBeneficiaryPath(path) ? beneficiaryContactUs : donorContactUs;

  static String volunteerForPath(String path) =>
      isBeneficiaryPath(path) ? beneficiaryVolunteer : volunteerForm;
}
