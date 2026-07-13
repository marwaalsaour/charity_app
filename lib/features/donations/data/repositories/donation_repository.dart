import '../models/donation_model.dart';
import '../models/donation_need_item.dart';

class DonationRepository {
  Future<List<DonationModel>> getDonations(DonationCategory category) async {
    await Future.delayed(const Duration(milliseconds: 500));

    const all = [
      // ── Education
      DonationModel(
        id: 1,
        nameKey: 'donations.student_ahmed_name',
        titleKey: 'donations.student_ahmed_title',
        descriptionKey: 'donations.student_ahmed_story',
        category: DonationCategory.education,
        raised: 800,
        goal: 1200,
        image: 'assets/image/photo1.jpg',
        needs: [
          DonationNeedItem(
            titleKey: 'donations.student_ahmed_need1_title',
            descKey: 'donations.student_ahmed_need1_desc',
            amount: 700,
          ),
          DonationNeedItem(
            titleKey: 'donations.student_ahmed_need2_title',
            descKey: 'donations.student_ahmed_need2_desc',
            amount: 300,
          ),
          DonationNeedItem(
            titleKey: 'donations.student_ahmed_need3_title',
            descKey: 'donations.student_ahmed_need3_desc',
            amount: 200,
          ),
        ],
      ),
      DonationModel(
        id: 6,
        nameKey: 'donations.student_nour_name',
        titleKey: 'donations.student_nour_title',
        descriptionKey: 'donations.student_nour_story',
        category: DonationCategory.education,
        raised: 420,
        goal: 900,
        image: 'https://picsum.photos/600/400?random=36',
        isUrgent: true,
        needs: [
          DonationNeedItem(
            titleKey: 'donations.student_nour_need1_title',
            descKey: 'donations.student_nour_need1_desc',
            amount: 400,
          ),
          DonationNeedItem(
            titleKey: 'donations.student_nour_need2_title',
            descKey: 'donations.student_nour_need2_desc',
            amount: 300,
          ),
          DonationNeedItem(
            titleKey: 'donations.student_nour_need3_title',
            descKey: 'donations.student_nour_need3_desc',
            amount: 200,
          ),
        ],
      ),
      DonationModel(
        id: 7,
        nameKey: 'donations.student_karim_name',
        titleKey: 'donations.student_karim_title',
        descriptionKey: 'donations.student_karim_story',
        category: DonationCategory.education,
        raised: 1840,
        goal: 2400,
        image: 'assets/image/photo2.jpg',
        isUrgent: true,
        techTitleKey: 'technical_requirements',
        techDescKey: 'donations.student_karim_tech_desc',
        techTagKeys: [
          'donations.student_karim_tech_tag1',
          'donations.student_karim_tech_tag2',
        ],
        needs: [
          DonationNeedItem(
            titleKey: 'donations.student_karim_need1_title',
            descKey: 'donations.student_karim_need1_desc',
            amount: 1600,
          ),
          DonationNeedItem(
            titleKey: 'donations.student_karim_need2_title',
            descKey: 'donations.student_karim_need2_desc',
            amount: 450,
          ),
          DonationNeedItem(
            titleKey: 'donations.student_karim_need3_title',
            descKey: 'donations.student_karim_need3_desc',
            amount: 350,
          ),
        ],
      ),
      // ── Medical
      DonationModel(
        id: 2,
        nameKey: 'donations.patient_ali_name',
        titleKey: 'donations.patient_ali_title',
        descriptionKey: 'donations.patient_ali_desc',
        storyKey: 'donations.patient_ali_story',
        category: DonationCategory.medical,
        raised: 200,
        goal: 1000,
        image: 'https://picsum.photos/600/400?random=32',
        isUrgent: true,
        hospitalKey: 'donations.patient_ali_hospital',
        doctorKey: 'donations.patient_ali_doctor',
        needs: [
          DonationNeedItem(
            titleKey: 'donations.patient_ali_need_title',
            descKey: 'donations.patient_ali_need_desc',
            amount: 1000,
          ),
        ],
      ),
      DonationModel(
        id: 4,
        nameKey: 'donations.patient_sara_name',
        titleKey: 'donations.patient_sara_title',
        descriptionKey: 'donations.patient_sara_desc',
        storyKey: 'donations.patient_sara_story',
        category: DonationCategory.medical,
        raised: 3500,
        goal: 8000,
        image: 'https://picsum.photos/600/400?random=33',
        isUrgent: true,
        hospitalKey: 'donations.patient_sara_hospital',
        doctorKey: 'donations.patient_sara_doctor',
        needs: [
          DonationNeedItem(
            titleKey: 'donations.patient_sara_need_title',
            descKey: 'donations.patient_sara_need_desc',
            amount: 8000,
          ),
        ],
      ),
      DonationModel(
        id: 5,
        nameKey: 'donations.patient_omar_name',
        titleKey: 'donations.patient_omar_title',
        descriptionKey: 'donations.patient_omar_desc',
        storyKey: 'donations.patient_omar_story',
        category: DonationCategory.medical,
        raised: 1200,
        goal: 4500,
        image: 'https://picsum.photos/600/400?random=34',
        hospitalKey: 'donations.patient_omar_hospital',
        doctorKey: 'donations.patient_omar_doctor',
        needs: [
          DonationNeedItem(
            titleKey: 'donations.patient_omar_need_title',
            descKey: 'donations.patient_omar_need_desc',
            amount: 4500,
          ),
        ],
      ),
      // ── Orphans
      DonationModel(
        id: 3,
        nameKey: 'donations.orphan_layla_name',
        titleKey: 'donations.orphan_layla_title',
        descriptionKey: 'donations.orphan_layla_desc',
        category: DonationCategory.orphans,
        raised: 450,
        goal: 1500,
        image: 'assets/image/photo3.jpg',
      ),
      DonationModel(
        id: 8,
        nameKey: 'donations.orphan_youssef_name',
        titleKey: 'donations.orphan_youssef_title',
        descriptionKey: 'donations.orphan_youssef_desc',
        category: DonationCategory.orphans,
        raised: 680,
        goal: 1800,
        image: 'https://picsum.photos/600/400?random=37',
      ),
      DonationModel(
        id: 9,
        nameKey: 'donations.orphan_mariam_name',
        titleKey: 'donations.orphan_mariam_title',
        descriptionKey: 'donations.orphan_mariam_desc',
        category: DonationCategory.orphans,
        raised: 920,
        goal: 2400,
        image: 'https://picsum.photos/600/400?random=38',
      ),
    ];

    return all.where((item) => item.category == category).toList();
  }
}
