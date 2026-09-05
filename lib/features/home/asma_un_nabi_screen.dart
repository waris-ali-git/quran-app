import 'package:flutter/material.dart';
import 'widgets/nabi_name_detail_overlay.dart';

class AsmaUnNabiScreen extends StatefulWidget {
  const AsmaUnNabiScreen({super.key});

  @override
  State<AsmaUnNabiScreen> createState() => _AsmaUnNabiScreenState();
}

class _AsmaUnNabiScreenState extends State<AsmaUnNabiScreen>
    with TickerProviderStateMixin {
  int? _activeIndex;
  late AnimationController _headerController;
  late Animation<double> _headerFade;

  final List<Map<String, String>> _names = [
    {
      "arabic": "مُحَمَّدٌ",
      "transliteration": "Muhammad",
      "meaning": "Oft-Praised",
      "description": "Muhammad is the most praised one. It is the proper name of the Final Messenger of Allah (PBUH). He is praised in the heavens and on earth, and by the past and future generations. The name signifies one who possesses a multitude of praiseworthy qualities."
    },
    {
      "arabic": "أَحْمَدٌ",
      "transliteration": "Ahmad",
      "meaning": "Greatest of Praisers",
      "description": "Ahmad signifies the one who praises Allah more than anyone else. It is a name mentioned in the Gospel (Injeel) as the name of the Prophet who was to come after Jesus (AS). It reflects his deep devotion and gratitude to his Creator."
    },
    {
      "arabic": "حَامِدٌ",
      "transliteration": "Hamid",
      "meaning": "Praiser",
      "description": "The one who constantly praises and thanks Allah. His life was a continuous act of worship and gratitude, setting the ultimate example for all believers on how to acknowledge the blessings of Allah."
    },
    {
      "arabic": "مَحْمُودٌ",
      "transliteration": "Mahmud",
      "meaning": "Praised One",
      "description": "The one who is worthy of praise and is praised for his noble character, actions, and the message he brought. He is the possessor of the 'Station of Praise' (Maqam al-Mahmud) on the Day of Judgment."
    },
    {
      "arabic": "أَحِيدُ",
      "transliteration": "Ahid",
      "meaning": "Repeller",
      "description": "The one who repels and protects his followers from the fire of Hell through his guidance and intercession. He is the barrier between his Ummah and destruction."
    },
    {
      "arabic": "وَحِيدٌ",
      "transliteration": "Wahid",
      "meaning": "Unique",
      "description": "The one who is unique in his character, station, and the perfection of his prophethood. No other human has reached the spiritual heights that he attained during the Isra and Mi'raj."
    },
    {
      "arabic": "مَاحٍ",
      "transliteration": "Mahi",
      "meaning": "Effacer",
      "description": "The one through whom Allah effaces and wipes away disbelief (kufr). His message brought light to the world and removed the darkness of ignorance and idolatry."
    },
    {
      "arabic": "حَاشِرٌ",
      "transliteration": "Hashir",
      "meaning": "Gatherer",
      "description": "The one at whose feet people will be gathered on the Day of Resurrection. He is the first to be raised from the grave and the leader of all humanity on that day."
    },
    {
      "arabic": "عَاقِبٌ",
      "transliteration": "Aqib",
      "meaning": "Last in Succession",
      "description": "The one who comes last in the line of prophets. There is no prophet after him. He is the seal of prophethood and the final messenger sent to all of mankind."
    },
    {
      "arabic": "طه",
      "transliteration": "Taha",
      "meaning": "Taha",
      "description": "One of the mysterious names of the Prophet mentioned in the Quran. It is often interpreted as 'O Man' or as a title of honour and endearment from Allah to His beloved messenger."
    },
    {
      "arabic": "يس",
      "transliteration": "Yasin",
      "meaning": "Yasin",
      "description": "A title of the Prophet and the name of a Surah in the Quran. It is considered the heart of the Quran and signifies the high spiritual status and purity of the Prophet (PBUH)."
    },
    {
      "arabic": "طَاهِرٌ",
      "transliteration": "Tahir",
      "meaning": "Pure One",
      "description": "The one who is pure in heart, soul, and body. He was protected from all spiritual and moral impurities, serving as a perfect vessel for the divine revelation."
    },
    {
      "arabic": "مُطَهَّرٌ",
      "transliteration": "Mutahhar",
      "meaning": "Purified",
      "description": "The one who was purified by Allah. This refers to the cleansing of his heart by the angels and his elevation to a state of absolute spiritual clarity and devotion."
    },
    {
      "arabic": "طَيِّبٌ",
      "transliteration": "Tayyib",
      "meaning": "Fragrant",
      "description": "The one who is good, pure, and pleasant. It refers not only to his physical fragrance but also to the pleasantness of his character and the sweetness of his speech."
    },
    {
      "arabic": "سَيِّدٌ",
      "transliteration": "Sayyid",
      "meaning": "Liegelord",
      "description": "The master and leader of all the children of Adam. He is the foremost of all humanity in rank and honor before Allah, yet he remained the most humble of all servants."
    },
    {
      "arabic": "رَسُولٌ",
      "transliteration": "Rasul",
      "meaning": "Emissary, or Messenger",
      "description": "The one sent by Allah with a divine message and a new law (Shariah). He is the bridge between the Creator and the creation, conveying the path to salvation."
    },
    {
      "arabic": "نَبِيٌّ",
      "transliteration": "Nabiyy",
      "meaning": "Prophet",
      "description": "The one who receives news and information from Allah. Every Rasul is a Nabi, signifying his role as a recipient of divine guidance and a warner to his people."
    },
    {
      "arabic": "رَسُولُ الرَّحْمَةِ",
      "transliteration": "Rasulu r-Rahmah",
      "meaning": "Emissary of Mercy",
      "description": "The messenger sent as a mercy to the entire universe. His teachings brought compassion to the heartless and justice to the oppressed, transforming society with love."
    },
    {
      "arabic": "قَيِّمٌ",
      "transliteration": "Qayyim",
      "meaning": "Upright",
      "description": "The one who is perfectly upright and steadfast in the truth. He never wavered from the path of Allah, even in the face of extreme hardship and opposition."
    },
    {
      "arabic": "جَامِعٌ",
      "transliteration": "Jami'",
      "meaning": "Embodier of all Virtues",
      "description": "The one who combined within himself all the noble qualities and virtues of all the previous prophets. He is the perfect example of human excellence in every aspect."
    },
    {
      "arabic": "مُقْتَفٍ",
      "transliteration": "Muqtafi",
      "meaning": "Successor to the Past Prophets",
      "description": "The one who followed the path of the previous prophets and completed their work. He is the heir to the legacy of all the messengers of Allah since Adam (AS)."
    },
    {
      "arabic": "مُقَفِّى",
      "transliteration": "Muqaffi",
      "meaning": "Surpasser",
      "description": "The one who came after the others and whose message surpassed and superseded all previous revelations, bringing the final and perfect version of the divine law."
    },
    {
      "arabic": "رَسُولُ الْمَلَاحِمِ",
      "transliteration": "Rasulu l-Malahim",
      "meaning": "Emissary who fought Battles",
      "description": "The messenger who was commanded to fight for the sake of justice and to establish the truth. His battles were not for power, but to protect the weak and end oppression."
    },
    {
      "arabic": "رَسُولُ الرَّاحَةِ",
      "transliteration": "Rasulu r-Rahah",
      "meaning": "Emissary of Comfort",
      "description": "The messenger who brought ease and comfort to the souls of the people. His presence and teachings removed the heavy burdens of ritualism and provided a path to spiritual rest."
    },
    {
      "arabic": "كَامِلٌ",
      "transliteration": "Kamil",
      "meaning": "Complete",
      "description": "The one who attained perfection in all attributes—spiritual, moral, and physical. He is the ultimate model of completion in the human journey towards Allah."
    },
    {
      "arabic": "إِكْلِيلٌ",
      "transliteration": "Iklil",
      "meaning": "Crown",
      "description": "The crown of all creation. He is the most precious and exalted part of the universe, representing the pinnacle of honor and dignity among all created beings."
    },
    {
      "arabic": "مُدَّثِّرٌ",
      "transliteration": "Muddaththir",
      "meaning": "Enwrapped in His Robe",
      "description": "A title mentioned in the Quran, referring to the moment when he received the first revelations and was enwrapped in his robe. It signifies his state of deep spiritual reflection and the weight of his mission."
    },
    {
      "arabic": "مُزَّمِّلٌ",
      "transliteration": "Muzzammil",
      "meaning": "Enwrapped in His Cloak",
      "description": "Another title from the Quran, referring to his state of devotion and prayer during the night. It highlights his intimate connection with Allah through late-night worship."
    },
    {
      "arabic": "عَبْدُ اللهِ",
      "transliteration": "Abdullah",
      "meaning": "Slave of Allah",
      "description": "The most perfect servant of Allah. This is his most beloved title, as true freedom is found only in absolute submission and servitude to the Creator."
    },
    {
      "arabic": "حَبِيبُ اللهِ",
      "transliteration": "Habibullah",
      "meaning": "Beloved of Allah",
      "description": "The one who is most dear to Allah. His relationship with the Divine was built on profound love and intimacy, making him the most cherished of all creation."
    },
    {
      "arabic": "صَفِيُّ اللهِ",
      "transliteration": "Safiyyullah",
      "meaning": "One Solely Chosen by Allah",
      "description": "The one who was chosen and distilled for the sake of Allah. He was selected from among all humanity to carry the final and most important message."
    },
    {
      "arabic": "نَجِيُّ اللهِ",
      "transliteration": "Najiyyullah",
      "meaning": "One who had Intimate Discourse with Allah",
      "description": "The one who enjoyed a special and direct conversation with Allah, especially during the Mi'raj. He shared secrets and guidance that were meant for him and his Ummah."
    },
    {
      "arabic": "كَلِيمُ اللهِ",
      "transliteration": "Kalimullah",
      "meaning": "One Addressed by Allah",
      "description": "The one to whom Allah spoke directly. This title highlights his direct access to divine guidance and the honor of being addressed by the Lord of the worlds."
    },
    {
      "arabic": "خَاتِمُ الْأَنْبِيَاءِ",
      "transliteration": "Khatimu l-Anbiya",
      "meaning": "Seal of the Prophets",
      "description": "The final prophet who closed the door of prophethood. His arrival signaled the completion of the divine mission on earth, and no prophet will come after him."
    },
    {
      "arabic": "خَاتِمُ الرُّسُلِ",
      "transliteration": "Khatimu r-Rusul",
      "meaning": "Seal of the Emissaries",
      "description": "The final messenger whose law and message will remain until the end of time. He sealed the line of messengers, bringing the ultimate and perfect revelation."
    },
    {
      "arabic": "مُحْيٍ",
      "transliteration": "Muhyi",
      "meaning": "Reviver",
      "description": "The one who revived dead hearts and brought life back to a world drowning in ignorance. His message breathed new life into the spiritual and moral existence of humanity."
    },
    {
      "arabic": "مُنْجٍ",
      "transliteration": "Munji",
      "meaning": "Deliverer",
      "description": "The one who delivers his followers from the darkness of sin and the punishment of the afterlife. He is the means of salvation for those who follow his path."
    },
    {
      "arabic": "مُذَكِّرٌ",
      "transliteration": "Mudhakkir",
      "meaning": "One Who Reminds",
      "description": "The one whose primary role was to remind humanity of their Creator and their purpose. He called people back to their natural state of faith and devotion."
    },
    {
      "arabic": "نَاصِرٌ",
      "transliteration": "Nasir",
      "meaning": "Bringer of Victory",
      "description": "The one who helps and supports the truth. Through his efforts and the help of Allah, the truth prevailed over falsehood and the believers were granted victory."
    },
    {
      "arabic": "مَنْصُورٌ",
      "transliteration": "Mansur",
      "meaning": "One Granted Victory",
      "description": "The one who was supported and made victorious by Allah. Despite all the attempts of his enemies, he was always granted the upper hand through divine assistance."
    },
    {
      "arabic": "نَبِيُّ الرَّحْمَةِ",
      "transliteration": "Nabiyyu r-Rahmah",
      "meaning": "Prophet of Mercy",
      "description": "The prophet whose entire mission and character were a manifestation of divine mercy. He showed compassion to all, including those who persecuted him."
    },
    {
      "arabic": "نَبِيُّ التَّوْبَةِ",
      "transliteration": "Nabiyyu t-Tawbah",
      "meaning": "Prophet of Repentance",
      "description": "The prophet who opened the way for repentance and forgiveness. He taught that the door to Allah is always open for those who sincerely return to Him."
    },
    {
      "arabic": "حَرِيصٌ عَلَيْكُمْ",
      "transliteration": "Harisun Alaykum",
      "meaning": "Most Concerned for You",
      "description": "A description from the Quran, highlighting his deep love and anxiety for the well-being and salvation of his Ummah. He cared for his followers more than they cared for themselves."
    },
    {
      "arabic": "مَعْلُومٌ",
      "transliteration": "Ma'lum",
      "meaning": "Known One",
      "description": "The one whose qualities and arrival were known and described in the previous scriptures. He was recognized by those who truly sought the truth among the people of the book."
    },
    {
      "arabic": "شَهِيرٌ",
      "transliteration": "Shahir",
      "meaning": "Renowned",
      "description": "The one whose fame and name are exalted throughout the world. In every corner of the earth, his name is praised and his memory is cherished by billions."
    },
    {
      "arabic": "شَاهِدٌ",
      "transliteration": "Shahid",
      "meaning": "Testifier",
      "description": "The one who will testify to the truth of the messages delivered by the previous prophets on the Day of Judgment. He is the primary witness for all of humanity."
    },
    {
      "arabic": "شَهِيدٌ",
      "transliteration": "Shahid",
      "meaning": "Witness",
      "description": "The one who witnesses the actions of his Ummah and is aware of their states. His presence and message serve as a witness for or against people based on their faith."
    },
    {
      "arabic": "مَشْهُودٌ",
      "transliteration": "Mashhud",
      "meaning": "One Witnessed to",
      "description": "The one whose truth and prophethood are witnessed by the signs of creation, the miracles he performed, and the hearts of the believers."
    },
    {
      "arabic": "بَشِيرٌ",
      "transliteration": "Bashir",
      "meaning": "Bearer of Good Tidings",
      "description": "The one who brings news of the immense rewards and paradise waiting for those who believe and do good. He is the herald of eternal happiness."
    },
    {
      "arabic": "مُبَشِّرٌ",
      "transliteration": "Mubashshir",
      "meaning": "Bringer of Good News",
      "description": "The one whose message is full of hope and glad tidings for the sincere. He brought the news of Allah's forgiveness and the success that follows obedience."
    },
    {
      "arabic": "نَذِيرٌ",
      "transliteration": "Nadhir",
      "meaning": "Warner",
      "description": "The one who warns humanity of the consequences of disbelief and evil actions. His warnings were out of love, to save people from the fire of Hell."
    },
    {
      "arabic": "مُنْذِرٌ",
      "transliteration": "Mundhir",
      "meaning": "Admonisher",
      "description": "The one who provides a clear and persistent warning. He admonished his people to turn back to Allah before it was too late, fulfilling his duty as a guardian."
    },
    {
      "arabic": "نُورٌ",
      "transliteration": "Nur",
      "meaning": "Light",
      "description": "The spiritual light that illuminates the path to Allah. His guidance removed the darkness of shirk and brought the radiance of tawhid to the world."
    },
    {
      "arabic": "سِرَاجٌ",
      "transliteration": "Siraj",
      "meaning": "Lamp",
      "description": "A lamp that provides light without heat, guiding the travelers in the night of ignorance. He is the source of clarity for all who seek the truth."
    },
    {
      "arabic": "مِصْبَاحٌ",
      "transliteration": "Misbah",
      "meaning": "Lantern",
      "description": "A lantern that is placed in a high position to guide everyone. His message is accessible and provides guidance to both the simple and the wise."
    },
    {
      "arabic": "هُدَىً",
      "transliteration": "Huda",
      "meaning": "Guidance",
      "description": "The embodiment of guidance. His entire life and teachings are the very definition of the path that leads to the pleasure of Allah."
    },
    {
      "arabic": "مَهْدِيٌ",
      "transliteration": "Mahdiyy",
      "meaning": "Guided",
      "description": "The one who was perfectly guided by Allah. He didn't speak from his own desires, but followed only what was revealed to him by the Divine."
    },
    {
      "arabic": "مُنِيرٌ",
      "transliteration": "Munir",
      "meaning": "Giver of Light",
      "description": "The one who makes things bright and clear. His presence and message clarify the complicated matters of life and provide a bright vision for the future."
    },
    {
      "arabic": "دَاعٍ",
      "transliteration": "Da'i",
      "meaning": "Caller",
      "description": "The one who calls humanity to the worship of the One True God. His call was gentle, persistent, and based on wisdom and clear proof."
    },
    {
      "arabic": "مَدْعُوٌّ",
      "transliteration": "Mad'uww",
      "meaning": "Called Upon",
      "description": "The one who was called and summoned by Allah to carry the heaviest burden of prophethood. He was chosen from among all to lead the final call."
    },
    {
      "arabic": "مُجِيبٌ",
      "transliteration": "Mujib",
      "meaning": "Answerer to the Call",
      "description": "The one who answered the call of Allah with absolute devotion. He said 'Labbayk' (I am at Your service) and dedicated every moment of his life to the Divine command."
    },
    {
      "arabic": "مُجَابٌ",
      "transliteration": "Mujab",
      "meaning": "Answered",
      "description": "The one whose prayers are always answered by Allah. He was given the privilege of intercession and his supplications for his Ummah are cherished by the Divine."
    },
    {
      "arabic": "حَفِيٌّ",
      "transliteration": "Hafiyy",
      "meaning": "Welcoming",
      "description": "The one who was kind and welcoming to everyone, even his enemies. He had a heart that was open and full of compassion for all of humanity."
    },
    {
      "arabic": "عَفُوٌّ",
      "transliteration": "Afuww",
      "meaning": "Much-Pardoning",
      "description": "The one who was extremely forgiving. He pardoned those who tried to kill him and showed that the greatest power is the power to forgive when one has the ability to punish."
    },
    {
      "arabic": "وَلِيٌّ",
      "transliteration": "Waliyy",
      "meaning": "One Close to Allah",
      "description": "The intimate friend and ally of Allah. His closeness to the Divine was the source of his strength and the reason for his unparalleled success."
    },
    {
      "arabic": "حَقٌ",
      "transliteration": "Haqq",
      "meaning": "Truth",
      "description": "The one who spoke only the truth and whose entire existence was a manifestation of the truth. He brought the final reality to a world lost in illusions."
    },
    {
      "arabic": "قَوِيٌّ",
      "transliteration": "Qawiyy",
      "meaning": "Mighty",
      "description": "The one who possessed immense spiritual and moral strength. He stood firm against all the powers of disbelief and never yielded in his mission."
    },
    {
      "arabic": "أَمِينٌ",
      "transliteration": "Amin",
      "meaning": "Trustworthy",
      "description": "The one who was known as 'The Trustworthy' even before his prophethood. He was the one with whom even his enemies would leave their most precious belongings."
    },
    {
      "arabic": "مَأْمُونٌ",
      "transliteration": "Ma'mun",
      "meaning": "Trusted",
      "description": "The one who was trusted by Allah to carry the most important message in human history. He was protected from ever betraying that trust in the slightest way."
    },
    {
      "arabic": "كَرِيمٌ",
      "transliteration": "Karim",
      "meaning": "Noble",
      "description": "The one who was the most noble in character and lineage. His generosity and nobility were shown to everyone, regardless of their status or background."
    },
    {
      "arabic": "مُكَرَّمٌ",
      "transliteration": "Mukarram",
      "meaning": "Ennobled",
      "description": "The one who was honored and ennobled by Allah. His station is higher than all other created beings, and he is the most honored in the sight of the Divine."
    },
    {
      "arabic": "مَكِينٌ",
      "transliteration": "Makin",
      "meaning": "Unshakeable",
      "description": "The one who had a firm and unshakeable position before Allah. He was granted an established rank that can never be questioned or removed."
    },
    {
      "arabic": "مَتِينٌ",
      "transliteration": "Matin",
      "meaning": "Firm",
      "description": "The one who was strong and firm in his resolve. He carried the heavy weight of the Quran and the mission of prophethood with absolute steadfastness."
    },
    {
      "arabic": "مُبِينٌ",
      "transliteration": "Mubin",
      "meaning": "Evident, Clarifier",
      "description": "The one who made the truth clear and evident for everyone. His message removed all doubt and provided a distinct path for those who seek the light."
    },
    {
      "arabic": "مُؤَمِّلٌ",
      "transliteration": "Mu'ammil",
      "meaning": "Hopeful",
      "description": "The one who gave hope to the hopeless. He taught that no matter how far one has strayed, the mercy of Allah is always within reach for those who seek it."
    },
    {
      "arabic": "وَصُولٌ",
      "transliteration": "Wasul",
      "meaning": "Maintainer of Ties",
      "description": "The one who excelled in maintaining the ties of kinship and friendship. He taught the importance of community and the bonds that unite the believers."
    },
    {
      "arabic": "ذُو قُوَّةٍ",
      "transliteration": "Dhu Quwwah",
      "meaning": "Possessor of Might",
      "description": "The one who possessed great spiritual and physical power given by Allah. He used this might only to establish justice and to protect the message of truth."
    },
    {
      "arabic": "ذُو حُرْمَةٍ",
      "transliteration": "Dhu Hurmah",
      "meaning": "Possessor of Sanctity",
      "description": "The one whose sanctity and honor are protected by Allah. Disrespecting him is a grave matter, as he is the most sacred of all created beings."
    },
    {
      "arabic": "ذُو مَكَانَةٍ",
      "transliteration": "Dhu Makanah",
      "meaning": "Possessor of a Mighty Station",
      "description": "The one who has a high and established rank in the sight of Allah. He is the master of the Praiseworthy Station and the leader of all prophets."
    },
    {
      "arabic": "ذُو عِزٍّ",
      "transliteration": "Dhu Izz",
      "meaning": "Possessor of Glory",
      "description": "The one who was granted true honor and glory by Allah. His name is exalted alongside the name of Allah in the Shahadah and the Adhan."
    },
    {
      "arabic": "ذُو فَضْلٍ",
      "transliteration": "Dhu Fadl",
      "meaning": "Possessor of Virtue",
      "description": "The one who was gifted with every noble quality and virtue. He is the source from which we learn the meaning of excellence and character."
    },
    {
      "arabic": "مُطَاعٌ",
      "transliteration": "Muta'",
      "meaning": "Obeyed",
      "description": "The one whose obedience is mandated by Allah. Obeying the Messenger is obeying Allah, and he is the ultimate authority in the affairs of the Ummah."
    },
    {
      "arabic": "مُطِيعٌ",
      "transliteration": "Muti'",
      "meaning": "Obedient",
      "description": "The one who was the most obedient to Allah. His entire life was a submission to the Divine will, and he never hesitated in any command."
    },
    {
      "arabic": "قَدَمُ صِدْقٍ",
      "transliteration": "Qadamu Sidq",
      "meaning": "Sure Forerunner",
      "description": "The one who is the true forerunner and leader in the path of sincerity. He established the precedent of truthfulness that all must follow."
    },
    {
      "arabic": "رَحْمَةٌ",
      "transliteration": "Rahmah",
      "meaning": "Mercy",
      "description": "The one who is a pure manifestation of divine mercy. His existence is a gift to the universe, bringing hope and healing to the broken-hearted."
    },
    {
      "arabic": "بُشْرَى",
      "transliteration": "Bushra",
      "meaning": "Glad Tidings",
      "description": "The glad tidings mentioned by the previous prophets. His arrival was the fulfillment of the long-awaited promise of a final messenger."
    },
    {
      "arabic": "غُوثٌ",
      "transliteration": "Ghawth",
      "meaning": "Aid",
      "description": "The one who provides spiritual and moral aid to his followers. He is the source of support for those who are struggling in the path of Allah."
    },
    {
      "arabic": "غَيْثٌ",
      "transliteration": "Ghayth",
      "meaning": "Relief",
      "description": "The rain of mercy that brings life to dead souls. His message provided the spiritual moisture needed for faith to grow in the hearts of humanity."
    },
    {
      "arabic": "غِيَاثٌ",
      "transliteration": "Ghiyath",
      "meaning": "Succour",
      "description": "The one who provides help and succour in times of distress. He is the ultimate intercessor who will seek relief for his Ummah on the Day of Judgment."
    },
    {
      "arabic": "نِعْمَةُ اللهِ",
      "transliteration": "Ni'matullah",
      "meaning": "Allah’s Blessing",
      "description": "The greatest blessing bestowed by Allah upon humanity. Having him as our prophet is a favor that can never be fully repaid or acknowledged."
    },
    {
      "arabic": "هَدِيَّةُ اللهِ",
      "transliteration": "Hadiyyatullah",
      "meaning": "Allah’s Gift",
      "description": "A precious gift from the Divine to the world. He was sent not because we deserved him, but as an act of pure generosity from the Creator."
    },
    {
      "arabic": "عُرْوَةٌ وُثْقَى",
      "transliteration": "Urwatun Wuthqa",
      "meaning": "Most Trusty Hold",
      "description": "The most reliable handhold that never breaks. Those who hold fast to his Sunnah and his love will never fall into destruction."
    },
    {
      "arabic": "صِرَاطُ اللهِ",
      "transliteration": "Siratullah",
      "meaning": "Path to Allah",
      "description": "The path that leads directly to the pleasure and knowledge of Allah. He is the map and the guide for the journey of the soul back to its Lord."
    },
    {
      "arabic": "صِرَاطٌ مُسْتَقِيمٌ",
      "transliteration": "Siratun Mustaqim",
      "meaning": "Straight Path",
      "description": "The straight and balanced path that avoids all extremes. His teachings provide the perfect middle way for a successful and meaningful life."
    },
    {
      "arabic": "ذِكْرُ اللهِ",
      "transliteration": "Dhikrullah",
      "meaning": "Remembrance of Allah",
      "description": "The one whose life and presence remind everyone of Allah. Mentioning him is an act of worship, and he is the teacher of how to truly remember the Divine."
    },
    {
      "arabic": "سَيْفُ اللهِ",
      "transliteration": "Sayfullah",
      "meaning": "Sword of Allah",
      "description": "The sword of Allah drawn against falsehood. He stood as the ultimate protector of the truth, cutting through the illusions of disbelief and paganism."
    },
    {
      "arabic": "حِزْبُ اللهِ",
      "transliteration": "Hizbullah",
      "meaning": "Party of Allah",
      "description": "The leader of the party of Allah. Those who follow him are the successful ones who have chosen the side of truth and righteousness."
    },
    {
      "arabic": "النَّجْمُ الثَّاقِبُ",
      "transliteration": "An-Najmu th-thaqib",
      "meaning": "Shining Star",
      "description": "A piercing and brilliant star that cuts through the darkness. His guidance is constant and provides a fixed point of reference for all seekers of truth."
    },
    {
      "arabic": "مُصْطَفَى",
      "transliteration": "Mustafa",
      "meaning": "Chosen",
      "description": "The one who was chosen and distilled for the sake of Allah. He was selected from all of humanity to carry the final and most perfect message."
    },
    {
      "arabic": "مُجْتَبَى",
      "transliteration": "Mujtaba",
      "meaning": "Selected",
      "description": "The one who was hand-picked by the Divine. His selection was based on the perfection of his soul and his unparalleled capacity for love and service."
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
        title: const Text('Asma un Nabi', style: TextStyle(color: Color(0xFF90BDE7), fontWeight: FontWeight.bold)),
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
                childAspectRatio: 1.15,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _NameCard(
                  index: index,
                  data: _names[index],
                  isActive: _activeIndex == index,
                  onTap: () {
                    setState(() => _activeIndex = index);
                    showNabiNameDetailOverlay(context, _names[index], index);
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
              'مُحَمَّدٌ رَسُولُ اللهِ',
              style: TextStyle(
                fontFamily: 'Jameel Noori',
                fontSize: 48,
                color: Color(0xFF6FA8D8),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            Text(
              'ASMĀ UN NABĪ',
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
              'The 100 Beautiful Names of Prophet Muhammad (PBUH)',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4A6B8A),
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
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
            Positioned(
              top: 8,
              left: 10,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFF90BDE7).withValues(alpha: 0.12),
                  border: Border.all(
                    color: isActive ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF90BDE7).withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xFF6FA8D8),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 22, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Text(
                        data['arabic']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Jameel Noori',
                          fontSize: 34,
                          height: 1.2,
                          color: isActive ? Colors.white : const Color(0xFF1A2E44),
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: isActive ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF90BDE7).withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 4),
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
                            color: isActive ? Colors.white : const Color(0xFF6FA8D8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          data['meaning']!,
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.2,
                            color: isActive ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF4A6B8A),
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
