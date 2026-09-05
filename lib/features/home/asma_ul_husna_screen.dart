import 'package:flutter/material.dart';
import 'widgets/name_detail_overlay.dart';

class AsmaUlHusnaScreen extends StatefulWidget {
  const AsmaUlHusnaScreen({super.key});

  @override
  State<AsmaUlHusnaScreen> createState() => _AsmaUlHusnaScreenState();
}

class _AsmaUlHusnaScreenState extends State<AsmaUlHusnaScreen>
    with TickerProviderStateMixin {
  int? _activeIndex;
  late AnimationController _headerController;
  late Animation<double> _headerFade;

  final List<Map<String, String>> _names = [
    {
      "arabic": "اللَّٰه",
      "transliteration": "Allah",
      "meaning": "The Greatest Name",
      "description": "Allah is the proper name of the One True God. It encompasses all the divine attributes and is the name that is never shared by any other. It signifies the One who is worshipped and the One who possesses the right to be worshipped by all of creation."
    },
    {
      "arabic": "الرَّحْمَٰن",
      "transliteration": "Ar-Rahman",
      "meaning": "The Most Gracious",
      "description": "The One who possesses vast and encompasses mercy that extends to all creatures in this world—believers and non-believers alike. His mercy is an essential part of His Being and is shown in the sustenance and care He provides to all."
    },
    {
      "arabic": "الرَّحِيم",
      "transliteration": "Ar-Raheem",
      "meaning": "The Most Merciful",
      "description": "The One who is especially merciful to the believers. While Ar-Rahman refers to His general mercy for all, Ar-Raheem refers to His specific mercy that leads to guidance, forgiveness, and eternal reward in the Hereafter."
    },
    {
      "arabic": "الْمَلِك",
      "transliteration": "Al-Malik",
      "meaning": "The King",
      "description": "The Absolute Ruler and Sovereign of all existence. He is the King who owns everything, governs everything, and has no need of any of His creation, while everything in creation is entirely dependent on Him."
    },
    {
      "arabic": "الْقُدُّوس",
      "transliteration": "Al-Quddus",
      "meaning": "The Most Pure",
      "description": "The One who is free from any imperfection, error, or shortcoming. He is far removed from anything that does not suit His Majesty and is the Source of all purity and holiness."
    },
    {
      "arabic": "السَّلَام",
      "transliteration": "As-Salam",
      "meaning": "The Source of Peace",
      "description": "The One who is free from all defects and whose creation is safe from any injustice from Him. He is the Giver of peace and security to His creation in this world and the next."
    },
    {
      "arabic": "الْمُؤْمِن",
      "transliteration": "Al-Mu'min",
      "meaning": "The Granter of Security",
      "description": "The One who confirms His oneness and provides security to His servants. He is the Source of faith and the One who protects His believers from the fear of injustice or oppression."
    },
    {
      "arabic": "الْمُهَيْمِن",
      "transliteration": "Al-Muhaymin",
      "meaning": "The Guardian",
      "description": "The One who witnesses all things and provides protection and supervision. He is the All-Watchful who encompasses all of His creation with His knowledge and care."
    },
    {
      "arabic": "الْعَزِيز",
      "transliteration": "Al-Aziz",
      "meaning": "The Almighty",
      "description": "The Invincible and Overpowering One who cannot be defeated. He possesses all power and might, and everything is humbled before His Greatness."
    },
    {
      "arabic": "الْجَبَّار",
      "transliteration": "Al-Jabbar",
      "meaning": "The Compeller",
      "description": "The One who restores and mends what is broken. He is also the One whose will is always executed, and none can resist His decree, yet He is compassionate to those who seek Him."
    },
    {
      "arabic": "الْمُتَكَبِّر",
      "transliteration": "Al-Mutakabbir",
      "meaning": "The Supreme",
      "description": "The One who is rightfully proud of His perfection and Greatness. He is exalted above all creation, and His Majesty is beyond human comprehension."
    },
    {
      "arabic": "الْخَالِق",
      "transliteration": "Al-Khaliq",
      "meaning": "The Creator",
      "description": "The One who brings things into existence from nothingness according to His will and determination. He creates with perfect proportions and wisdom."
    },
    {
      "arabic": "الْبَارِئ",
      "transliteration": "Al-Bari'",
      "meaning": "The Originator",
      "description": "The One who creates everything with distinction and order, making each part of creation fit its intended purpose perfectly."
    },
    {
      "arabic": "الْمُصَوِّر",
      "transliteration": "Al-Musawwir",
      "meaning": "The Fashioner",
      "description": "The One who gives unique forms and shapes to everything He creates. No two things are exactly alike, and each reflects His infinite creativity."
    },
    {
      "arabic": "الْغَفَّار",
      "transliteration": "Al-Ghaffar",
      "meaning": "The Ever-Forgiving",
      "description": "The One who forgives time and again. He covers the sins of His servants and does not expose them, showing infinite patience and mercy."
    },
    {
      "arabic": "الْقَهَّار",
      "transliteration": "Al-Qahhar",
      "meaning": "The Subduer",
      "description": "The One who has absolute power to prevail over everything. All of creation is under His control and must submit to His will."
    },
    {
      "arabic": "الْوَهَّاب",
      "transliteration": "Al-Wahhab",
      "meaning": "The Bestower",
      "description": "The One who gives gifts and blessings freely and without any expectation of return. His generosity is limitless and reaches all His creation."
    },
    {
      "arabic": "الرَّزَّاق",
      "transliteration": "Ar-Razzaq",
      "meaning": "The Provider",
      "description": "The One who provides all that is necessary for the survival and well-being of His creation, both physically and spiritually."
    },
    {
      "arabic": "الْفَتَّاح",
      "transliteration": "Al-Fattah",
      "meaning": "The Opener",
      "description": "The One who opens the doors of mercy, sustenance, and knowledge. He is the Ultimate Judge who clarifies what is hidden and grants victory to the truth."
    },
    {
      "arabic": "الْعَلِيم",
      "transliteration": "Al-'Alim",
      "meaning": "The All-Knowing",
      "description": "The One whose knowledge encompasses everything—past, present, and future, hidden or manifest. Nothing escapes His infinite awareness."
    },
    {
      "arabic": "الْقَابِض",
      "transliteration": "Al-Qabid",
      "meaning": "The Withholder",
      "description": "The One who restrains or withholds sustenance and life according to His wisdom. He tests His servants by what He withholds."
    },
    {
      "arabic": "الْبَاسِط",
      "transliteration": "Al-Basit",
      "meaning": "The Extender",
      "description": "The One who expands or grants abundance. He provides generously to whom He wills, showing His infinite mercy and kindness."
    },
    {
      "arabic": "الْخَافِض",
      "transliteration": "Al-Khafid",
      "meaning": "The Reducer",
      "description": "The One who lowers or debases those who are arrogant and rebellious. He reduces the status of the wicked while exalting the righteous."
    },
    {
      "arabic": "الرَّافِع",
      "transliteration": "Ar-Rafi'",
      "meaning": "The Exalter",
      "description": "The One who raises the status and rank of those who believe and do good deeds. He exalts the hearts of His friends with knowledge and faith."
    },
    {
      "arabic": "الْمُعِز",
      "transliteration": "Al-Mu'izz",
      "meaning": "The Honourer",
      "description": "The One who grants honour and dignity to whom He wills. True honour is only found in obedience to Him and His guidance."
    },
    {
      "arabic": "الْمُذِل",
      "transliteration": "Al-Mudhill",
      "meaning": "The Humiliator",
      "description": "The One who humbles and disgraces those who reject the truth and persist in evil. He shows that all pride outside of Him is fleeting."
    },
    {
      "arabic": "السَّمِيع",
      "transliteration": "As-Sami'",
      "meaning": "The All-Hearing",
      "description": "The One who hears everything—every word, every whisper, and even the silent thoughts of the heart. His hearing is perfect and without limit."
    },
    {
      "arabic": "الْبَصِير",
      "transliteration": "Al-Basir",
      "meaning": "The All-Seeing",
      "description": "The One who sees everything—the manifest and the hidden, the large and the small. His sight encompasses all of existence perfectly."
    },
    {
      "arabic": "الْحَكَم",
      "transliteration": "Al-Hakam",
      "meaning": "The Judge",
      "description": "The Ultimate Judge whose decree is final and whose justice is perfect. He distinguishes between truth and falsehood with absolute wisdom."
    },
    {
      "arabic": "الْعَدْل",
      "transliteration": "Al-'Adl",
      "meaning": "The Just",
      "description": "The One who is perfectly equitable and just in all His actions and decrees. He is far removed from any form of injustice or bias."
    },
    {
      "arabic": "اللَّطِيف",
      "transliteration": "Al-Latif",
      "meaning": "The Subtle",
      "description": "The One who is gentle and aware of the finest details of all things. He grants His blessings in subtle and unexpected ways."
    },
    {
      "arabic": "الْخَبِير",
      "transliteration": "Al-Khabir",
      "meaning": "The All-Aware",
      "description": "The One who has full and intimate knowledge of the true nature of all things, including the secrets hidden in the depths of the soul."
    },
    {
      "arabic": "الْحَلِيم",
      "transliteration": "Al-Halim",
      "meaning": "The Forbearing",
      "description": "The One who is patient and slow to punish. He gives His servants time to repent and return to Him, despite their many transgressions."
    },
    {
      "arabic": "الْعَظِيم",
      "transliteration": "Al-'Azim",
      "meaning": "The Magnificent",
      "description": "The One whose Greatness is beyond all bounds. He is the possessor of all attributes of majesty and glory, and none can equal His stature."
    },
    {
      "arabic": "الْغَفُور",
      "transliteration": "Al-Ghafur",
      "meaning": "The Forgiving",
      "description": "The One who forgives extensively and repeatedly. He covers the sins of His servants and protects them from the consequences of their errors."
    },
    {
      "arabic": "الشَّكُور",
      "transliteration": "Ash-Shakur",
      "meaning": "The Appreciative",
      "description": "The One who rewards even the smallest of good deeds with immense rewards. He appreciates the gratitude of His servants and increases His blessings upon them."
    },
    {
      "arabic": "الْعَلِىّ",
      "transliteration": "Al-'Ali",
      "meaning": "The Most High",
      "description": "The One who is exalted above all things. His rank, power, and essence are uniquely superior to everything in creation."
    },
    {
      "arabic": "الْكَبِير",
      "transliteration": "Al-Kabir",
      "meaning": "The Most Great",
      "description": "The One who is the Greatest in every sense. His essence and attributes are so vast that they cannot be fully grasped by the human mind."
    },
    {
      "arabic": "الْحَفِيظ",
      "transliteration": "Al-Hafiz",
      "meaning": "The Preserver",
      "description": "The One who guards and preserves all things from harm and loss. He records all deeds and sustains the entire universe with His care."
    },
    {
      "arabic": "الْمُقِيت",
      "transliteration": "Al-Muqit",
      "meaning": "The Sustainer",
      "description": "The One who provides nourishment and support to all living things. He is the Source of all strength and sustenance needed for life."
    },
    {
      "arabic": "الْحَسِيب",
      "transliteration": "Al-Hasib",
      "meaning": "The Reckoner",
      "description": "The One who is sufficient for His servants and takes account of everything. He is the only one who can truly judge the intentions and actions of all."
    },
    {
      "arabic": "الْجَلِيل",
      "transliteration": "Al-Jalil",
      "meaning": "The Majestic",
      "description": "The One who possesses all the attributes of majesty and glory. He is exalted above all and is the Source of all true greatness."
    },
    {
      "arabic": "الْكَرِيم",
      "transliteration": "Al-Karim",
      "meaning": "The Generous",
      "description": "The One who is overflowing with generosity and kindness. He gives even without being asked and forgives even when He has the power to punish."
    },
    {
      "arabic": "الرَّقِيب",
      "transliteration": "Ar-Raqib",
      "meaning": "The Watchful",
      "description": "The One who observes all things constantly and intimately. Nothing in the heavens or the earth is hidden from His watchful gaze."
    },
    {
      "arabic": "الْمُجِيب",
      "transliteration": "Al-Mujib",
      "meaning": "The Responsive",
      "description": "The One who answers the calls and prayers of His servants. He is close to those who seek Him and responds to their needs with wisdom."
    },
    {
      "arabic": "الْوَاسِع",
      "transliteration": "Al-Wasi'",
      "meaning": "The All-Encompassing",
      "description": "The One whose capacity and knowledge are boundless. His mercy, sustenance, and wisdom encompass all of creation."
    },
    {
      "arabic": "الْحَكِيم",
      "transliteration": "Al-Hakim",
      "meaning": "The Wise",
      "description": "The One who acts with perfect wisdom in all His decrees and actions. Everything He does is for a purposeful and beneficial reason."
    },
    {
      "arabic": "الْوَدُود",
      "transliteration": "Al-Wadud",
      "meaning": "The Loving",
      "description": "The One who loves His righteous servants and is loved by them. His love is the source of all peace and contentment in the heart."
    },
    {
      "arabic": "الْمَاجِد",
      "transliteration": "Al-Majid",
      "meaning": "The Glorious",
      "description": "The One whose glory and majesty are beyond all bounds. He is the most honorable and exalted in His essence and deeds."
    },
    {
      "arabic": "الْبَاعِث",
      "transliteration": "Al-Ba'ith",
      "meaning": "The Resurrector",
      "description": "The One who will raise the dead from their graves on the Day of Judgment to face their reckoning. He is the Giver of new life."
    },
    {
      "arabic": "الشَّهِيد",
      "transliteration": "Ash-Shahid",
      "meaning": "The Witness",
      "description": "The One who is present and aware of all things at all times. He is the ultimate witness to every action and intention."
    },
    {
      "arabic": "الْحَق",
      "transliteration": "Al-Haqq",
      "meaning": "The Truth",
      "description": "The Absolute Reality whose existence is certain and unchanging. He is the Source of all truth and the One whose promise is always true."
    },
    {
      "arabic": "الْوَكِيل",
      "transliteration": "Al-Wakil",
      "meaning": "The Trustee",
      "description": "The One who is the most reliable guardian and disposer of all affairs. Those who trust in Him will find Him sufficient for all their needs."
    },
    {
      "arabic": "الْقَوِىّ",
      "transliteration": "Al-Qawiyy",
      "meaning": "The All-Strong",
      "description": "The One who possesses absolute and perfect strength. His power is limitless and nothing can resist His will."
    },
    {
      "arabic": "الْمَتِين",
      "transliteration": "Al-Matin",
      "meaning": "The Firm",
      "description": "The One who is steady and unchanging in His strength and power. He is the ultimate support that never fails."
    },
    {
      "arabic": "الْوَلِىّ",
      "transliteration": "Al-Waliyy",
      "meaning": "The Protecting Friend",
      "description": "The One who is the ally and protector of the believers. He guides them out of darkness into light and supports them against their enemies."
    },
    {
      "arabic": "الْحَمِيد",
      "transliteration": "Al-Hamid",
      "meaning": "The Praiseworthy",
      "description": "The One who is worthy of all praise and gratitude. All beauty and goodness in creation are a reflection of His perfect attributes."
    },
    {
      "arabic": "الْمُحْصِى",
      "transliteration": "Al-Muhsi",
      "meaning": "The Reckoner",
      "description": "The One who counts and records every single thing in existence. Nothing is too small or too large for Him to keep track of perfectly."
    },
    {
      "arabic": "الْمُبْدِئ",
      "transliteration": "Al-Mubdi'",
      "meaning": "The Originator",
      "description": "The One who began the creation of the universe from nothingness. He is the Source of all that exists."
    },
    {
      "arabic": "الْمُعِيد",
      "transliteration": "Al-Mu'id",
      "meaning": "The Restorer",
      "description": "The One who will restore all things to their original state after they have perished. He will bring everyone back to life for judgment."
    },
    {
      "arabic": "الْمُحْيِى",
      "transliteration": "Al-Muhyi",
      "meaning": "The Giver of Life",
      "description": "The One who grants life to the living and will give life to the dead. He is the Source of all vitality and existence."
    },
    {
      "arabic": "الْمُمِيت",
      "transliteration": "Al-Mumit",
      "meaning": "The Taker of Life",
      "description": "The One who decrees death for all living things according to His wisdom. He is the ultimate controller of the end of all earthly existence."
    },
    {
      "arabic": "الْحَىّ",
      "transliteration": "Al-Hayy",
      "meaning": "The Ever-Living",
      "description": "The One who is eternally alive and never dies. He is the Source of all life and His existence has no beginning and no end."
    },
    {
      "arabic": "الْقَيُّوم",
      "transliteration": "Al-Qayyum",
      "meaning": "The Self-Sustaining",
      "description": "The One who sustains Himself and everything else in existence. All of creation depends on Him for every moment of its being."
    },
    {
      "arabic": "الْوَاجِد",
      "transliteration": "Al-Wajid",
      "meaning": "The Finder",
      "description": "The One who finds whatever He wills instantly. He possesses everything and nothing can be hidden or lost from Him."
    },
    {
      "arabic": "الْمَاجِد",
      "transliteration": "Al-Majid",
      "meaning": "The Noble",
      "description": "The One who is full of honour and generosity. He is exalted in His essence and deeds, and His majesty is beyond compare."
    },
    {
      "arabic": "الْوَاحِد",
      "transliteration": "Al-Wahid",
      "meaning": "The One",
      "description": "The One who is uniquely singular in His essence and attributes. He has no partner or equal in His divinity."
    },
    {
      "arabic": "الْأَحَد",
      "transliteration": "Al-Ahad",
      "meaning": "The Unique",
      "description": "The One who is absolutely indivisible and alone in His majesty. He is the Only One whose existence is necessary and eternal."
    },
    {
      "arabic": "الصَّمَد",
      "transliteration": "As-Samad",
      "meaning": "The Eternal",
      "description": "The One on whom all depend for their needs, while He depends on none. He is the ultimate refuge and the Source of all satisfaction."
    },
    {
      "arabic": "الْقَادِر",
      "transliteration": "Al-Qadir",
      "meaning": "The Capable",
      "description": "The One who has absolute power to do anything He wills. His capability is perfect and encompasses all of existence."
    },
    {
      "arabic": "الْمُقْتَدِر",
      "transliteration": "Al-Muqtadir",
      "meaning": "The Powerful",
      "description": "The One whose power prevails over all affairs. He is the All-Powerful whose decree cannot be resisted or changed."
    },
    {
      "arabic": "الْمُقَدِّم",
      "transliteration": "Al-Muqaddim",
      "meaning": "The Expediter",
      "description": "The One who brings forward whatever He wills according to His wisdom. He facilitates the path for those He chooses."
    },
    {
      "arabic": "الْمُؤَخِّر",
      "transliteration": "Al-Mu'akhkhir",
      "meaning": "The Delayer",
      "description": "The One who delays or puts back whatever He wills according to His wisdom. He tests His servants by what He postpones."
    },
    {
      "arabic": "الْأَوَّل",
      "transliteration": "Al-Awwal",
      "meaning": "The First",
      "description": "The One who existed before anything else was created. He has no beginning and is the Source of all things."
    },
    {
      "arabic": "الْآخِر",
      "transliteration": "Al-Akhir",
      "meaning": "The Last",
      "description": "The One who will remain after everything else has perished. He has no end and is the ultimate destination of all creation."
    },
    {
      "arabic": "الظَّاهِر",
      "transliteration": "Az-Zahir",
      "meaning": "The Manifest",
      "description": "The One who is evident through His signs and creation. His existence is proven by the order and beauty of the universe."
    },
    {
      "arabic": "الْبَاطِن",
      "transliteration": "Al-Batin",
      "meaning": "The Hidden",
      "description": "The One whose essence is beyond all human perception and comprehension. He is closer to us than our own jugular vein."
    },
    {
      "arabic": "الْوَالِى",
      "transliteration": "Al-Wali",
      "meaning": "The Governor",
      "description": "The One who manages and governs all the affairs of the universe. Nothing happens without His permission and decree."
    },
    {
      "arabic": "الْمُتَعَالِى",
      "transliteration": "Al-Muta'ali",
      "meaning": "The Self-Exalted",
      "description": "The One who is supremely high and exalted above all creation. His majesty is beyond any comparison or description."
    },
    {
      "arabic": "الْبَرّ",
      "transliteration": "Al-Barr",
      "meaning": "The Source of Goodness",
      "description": "The One who is kind and gracious to all His creation. He is the Source of all benefit and goodness that we experience."
    },
    {
      "arabic": "التَّوَّاب",
      "transliteration": "At-Tawwab",
      "meaning": "The Accepter of Repentance",
      "description": "The One who repeatedly turns to His servants with forgiveness. He accepts the sincere repentance of those who return to Him."
    },
    {
      "arabic": "الْمُنْتَقِم",
      "transliteration": "Al-Muntaqim",
      "meaning": "The Avenger",
      "description": "The One who justly punishes those who persist in evil and oppression. His punishment is a reflection of His perfect justice."
    },
    {
      "arabic": "الْعَفُوّ",
      "transliteration": "Al-'Afuww",
      "meaning": "The Pardoner",
      "description": "The One who erases sins completely as if they never happened. His pardon is vast and encompasses all who seek it."
    },
    {
      "arabic": "الرَّءُوف",
      "transliteration": "Ar-Ra'uf",
      "meaning": "The Most Kind",
      "description": "The One who is full of compassion and tenderness. His kindness is shown in His protection and care for all His creation."
    },
    {
      "arabic": "مَالِكُ الْمُلْك",
      "transliteration": "Malik-ul-Mulk",
      "meaning": "The Owner of Sovereignty",
      "description": "The One who possesses absolute ownership and dominion over all of existence. Everything belongs to Him alone."
    },
    {
      "arabic": "ذُو الْجَلَالِ وَالْإِكْرَام",
      "transliteration": "Dhul-Jalali wal-Ikram",
      "meaning": "Lord of Majesty",
      "description": "The One who possesses all majesty, glory, and generosity. He is the Source of all honor and the One worthy of all respect."
    },
    {
      "arabic": "الْمُقْسِط",
      "transliteration": "Al-Muqsit",
      "meaning": "The Equitable",
      "description": "The One who acts with perfect justice and equity. He rewards the righteous and punishes the wicked with absolute fairness."
    },
    {
      "arabic": "الْجَامِع",
      "transliteration": "Al-Jami'",
      "meaning": "The Gatherer",
      "description": "The One who will gather all of humanity on the Day of Judgment. He brings together hearts and souls according to His will."
    },
    {
      "arabic": "الْغَنِىّ",
      "transliteration": "Al-Ghani",
      "meaning": "The Self-Sufficient",
      "description": "The One who is free of all needs and entirely independent. All of creation depends on Him, while He needs nothing from them."
    },
    {
      "arabic": "الْمُغْنِى",
      "transliteration": "Al-Mughni",
      "meaning": "The Enricher",
      "description": "The One who grants richness and abundance to whom He wills. True richness is the contentment He grants to the heart."
    },
    {
      "arabic": "الْمَانِع",
      "transliteration": "Al-Mani'",
      "meaning": "The Preventer",
      "description": "The One who withholds or prevents harm and evil from His servants according to His wisdom. He protects us from what we do not know."
    },
    {
      "arabic": "الضَّار",
      "transliteration": "Ad-Darr",
      "meaning": "The Distresser",
      "description": "The One who creates harm and trials as a test for His servants. He shows that all power to benefit or harm belongs to Him alone."
    },
    {
      "arabic": "النَّافِع",
      "transliteration": "An-Nafi'",
      "meaning": "The Propitious",
      "description": "The One who creates all benefit and goodness. He is the Source of all success and happiness in this world and the next."
    },
    {
      "arabic": "النُّور",
      "transliteration": "An-Nur",
      "meaning": "The Light",
      "description": "The One who illuminates the heavens and the earth with His guidance. He is the Source of all knowledge and faith in the heart."
    },
    {
      "arabic": "الْهَادِى",
      "transliteration": "Al-Hadi",
      "meaning": "The Guide",
      "description": "The One who leads His servants to the straight path of truth and righteousness. Without His guidance, we would be lost."
    },
    {
      "arabic": "الْبَدِيع",
      "transliteration": "Al-Badi'",
      "meaning": "The Incomparable",
      "description": "The One who created the universe with absolute uniqueness and without any prior model. His creativity is infinite and beyond compare."
    },
    {
      "arabic": "الْبَاقِى",
      "transliteration": "Al-Baqi",
      "meaning": "The Everlasting",
      "description": "The One who will remain eternally after everything else has perished. He is the only constant in an ever-changing universe."
    },
    {
      "arabic": "الْوَارِث",
      "transliteration": "Al-Warith",
      "meaning": "The Inheritor",
      "description": "The One who will inherit everything after its owners have passed away. Everything ultimately returns to Him alone."
    },
    {
      "arabic": "الرَّشِيد",
      "transliteration": "Ar-Rashid",
      "meaning": "The Guide to Right Path",
      "description": "The One whose guidance is perfect and whose decrees are always wise. He leads His servants to what is best for them."
    },
    {
      "arabic": "الصَّبُور",
      "transliteration": "As-Sabur",
      "meaning": "The Patient",
      "description": "The One who is never hasty in punishment. He gives His servants time and opportunities to repent, showing infinite patience."
    }
  ];

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _headerFade = CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFF), // TasbeehColors.background
      appBar: AppBar(
        title: const Text('Asma ul Husna', style: TextStyle(color: Color(0xFF90BDE7))),
        backgroundColor: const Color(0xFFFAFDFF),
        iconTheme: const IconThemeData(color: Color(0xFF90BDE7)),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.15, // Made smaller and wider
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _NameCard(
                  index: index,
                  data: _names[index],
                  isActive: _activeIndex == index,
                  onTap: () async {
                    setState(() => _activeIndex = index);
                    await showNameDetailOverlay(context, _names[index], index);
                    setState(() => _activeIndex = null);
                  },
                ),
                childCount: _names.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD9F1FD), Color(0xFFFAFDFF)],
          ),
        ),
        child: Column(
          children: [
            const Text(
              'بِسْمِ اللَّٰهِ',
              style: TextStyle(
                fontFamily: 'Jameel Noori',
                fontSize: 52,
                color: Color(0xFF6FA8D8),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            Text(
              'ASMĀ UL ḤUSNĀ',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 13,
                letterSpacing: 6,
                color: Color(0xFF1A2E44),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The 99 Beautiful Names of Allah',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4A6B8A),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  const Color(0xFF90BDE7).withValues(alpha: 0.6),
                  Colors.transparent,
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  final int index;
  final Map<String, String> data;
  final bool isActive;
  final VoidCallback onTap;

  const _NameCard({
    required this.index,
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEven = index % 2 == 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF90BDE7), Color(0xFF6FA8D8)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFDBE9FA)],
                ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? const Color(0xFF90BDE7).withValues(alpha: 0.35)
                  : const Color(0xFF90BDE7).withValues(alpha: 0.1),
              blurRadius: isActive ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isActive
                ? const Color(0xFF90BDE7).withValues(alpha: 0.8)
                : const Color(0xFF90BDE7).withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Number badge
            Positioned(
              top: 8,
              left: 10,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? const Color(0xFF90BDE7).withValues(alpha: 0.2)
                      : const Color(0xFF90BDE7).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFF90BDE7).withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF6FA8D8),
                    ),
                  ),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 22, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Arabic name
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Text(
                        data['arabic']!,
                        style: TextStyle(
                          fontFamily: 'Jameel Noori',
                          fontSize: 34,
                          height: 1.2,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF1A2E44),
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Divider
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: const Color(0xFF90BDE7).withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 4),
                  // Transliteration
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data['transliteration']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF6FA8D8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 1),
                        // Meaning
                        Text(
                          data['meaning']!,
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.2,
                            color: isActive
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF4A6B8A),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

