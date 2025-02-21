import 'package:flutter/material.dart';
import 'package:pyramid_puzzle/global_properties.dart';

String displaySectionName(String originalName) {
  final Map<String, String> sectionNames = {
    'Ana Bölüm 1': 'KEOPS PİRAMİDİ',
    'Ana Bölüm 2': 'KHAFRE PİRAMİDİ',
    'Ana Bölüm 3': 'MENKAURE PİRAMİDİ',
    'Ana Bölüm 4': 'DJOSER PİRAMİDİ',
    'Ana Bölüm 5': 'BENT PİRAMİT',
    'Ana Bölüm 6': 'MEİDUM PİRAMİDİ',
    'Ana Bölüm 7': 'MEROE PİRAMİDİ',
    'Ana Bölüm 8': 'GÜNEŞ PİRAMİDİ',
    'Ana Bölüm 9': 'TİKAL PİRAMİDİ',
    'Ana Bölüm 10': 'PALENQUE PİRAMİDİ',
    'Ana Bölüm 11': 'CALAKMUL PİRAMİDİ',
    'Ana Bölüm 12': 'EL CASTİLLO',
    'Ana Bölüm 13': 'CESTİUS PİRAMİDİ',
    'Ana Bölüm 14': 'CANDİ SUKUH PİRAMİDİ',
  };
  return sectionNames[originalName] ?? originalName;
}

class InfoDialog extends StatelessWidget {
  final String sectionName; // Örneğin "Ana Bölüm 1"

  const InfoDialog({
    Key? key,
    required this.sectionName,
  }) : super(key: key);

  String getTitle() {
    return displaySectionName(sectionName);
  }

  String getContent() {
    switch (sectionName) {
      // MARK: KEOPS 
      case "Ana Bölüm 1":
        return """Keops Piramidi, Mısır’ın Gize Platosu’nda yer alan ve antik dünyanın yedi harikasından biri olarak kabul edilen devasa bir anıtsal mezardır. Firavun Khufu (Keops) adına MÖ 2580–2560 yılları arasında inşa edilen bu yapı, dönemin ileri mühendislik ve mimarlık bilgisinin en etkileyici örneklerinden biridir.

        Gize’de, Kahire’ye yaklaşık 15 km mesafede bulunan piramit, Nil Nehri’nin batı kıyısında stratejik bir konumda yer alır. Bu konum, hem dini hem de astronomik hizalamalar açısından büyük önem taşır. Piramitin dört yüzü, neredeyse mükemmel şekilde kuzey, güney, doğu ve batı yönlerine denk gelecek biçimde konumlanmıştır; bu durum, Mısırlı mühendislerin astronomi ve geometrik prensiplere ne kadar hakim olduklarını göstermektedir.

        İnşaatı yaklaşık 20 yıl süren Keops Piramidi, orijinal yüksekliğinin 146,7 metre civarında olduğu, ancak zamanla dış kaplama taşlarının kaybı sonucu günümüzde yaklaşık 138,8 metreye düştüğü tespit edilmiştir. Tabanı, her kenarı yaklaşık 230,34 metre olan mükemmel bir kare şeklindedir ve yaklaşık 2,3 milyon adet, her biri ortalama 2,5 ton ağırlığında taş blok kullanılarak inşa edilmiştir. Bu devasa taş bloklar, Tura kireçtaşı ve Aswan granitinin kullanılmasıyla elde edilmiş; taşların kesilip, taş ocaklarından çıkarılarak inşaat alanına taşınmasında rampalar, kızaklar ve basit kaldıraç sistemleri gibi yöntemler kullanılmıştır.

        Piramidin iç yapısı da en az dış cephesindeki kadar dikkat çekicidir. Dar tüneller, geniş bir Büyük Galeri, Kral Odası ve Kraliçe Odası gibi bölümler, yapıdaki karmaşık geçit sistemini oluşturur. Kral Odası, Firavun Khufu’nun lahitinin yer aldığı odadır ve granit taşlardan ustalıkla oyulmuştur. Yanındaki Kraliçe Odası ise hâlâ tartışmalı yönleri olan gizemli geçitler ve havalandırma şaftları içerir. Modern tarama teknikleriyle yapılan araştırmalar, piramitin içinde keşfedilmeyi bekleyen gizli boşluklar ve odalar bulunduğunu göstermiştir.

        Keops Piramidi aynı zamanda astronomik ve matematiksel özellikleriyle de öne çıkar. Yapının dört yüzünün kardinal yönlere hizalanması, piramitin inşa edildiği dönemdeki astronomik bilgiyi yansıtırken; taban çevresi ile yüksekliğinin oranı, yaklaşık olarak pi (π) sayısına denk gelmesi, Mısırlıların matematiksel hassasiyetini gözler önüne serer.""";
      // MARK: KHAFRE
      case "Ana Bölüm 2":
        return """Khafre (Kefren) Piramidi, Mısır’ın Giza Platosu’nda yer alan üç büyük piramit arasında ikinci en büyüğü olarak dikkat çeker. Dördüncü Hanedanlık döneminde, MÖ 2558–2532 yılları arasında inşa edildiği düşünülen bu piramit, firavun Khafre için yaptırılmıştır. Khafre, büyük babası Keops’un (Khufu) oğlu olup, Giza kompleksi içinde mimari ve kültürel açıdan önemli bir yer tutar.
 
        Giza Platosu’nun güneybatısında yer alan Khafre Piramidi, bulunduğu yüksek zeminin etkisiyle uzaktan daha büyük görünür. Piramidin taban uzunluğu yaklaşık 215,25 metre, orijinal yüksekliği 143,5 metre olarak kabul edilirken, günümüzde erozyon ve kaplama taşlarının kaybı nedeniyle yaklaşık 136,4 metre yüksekliğe ulaşmaktadır. Yaklaşık %53,2’lik bir eğimle inşa edilmiş olması, onun görsel olarak etkileyici duruşunu pekiştirir.

        Khafre Piramidi, devasa kireçtaşı blokları ve bazı bölümlerde granit kullanılarak inşa edilmiştir. İnşaat sürecinde, çevredeki taş ocaklarından çıkarılan bloklar, rampalar, kızaklar ve basit kaldıraç sistemleri yardımıyla piramit alanına taşınmış ve özenle yerleştirilmiştir. Özellikle tepesinde, orijinal kaplama taşlarından kalan kısımlar günümüze ulaşmış olup, piramidin ilk görünüme dair ipuçları sunar. Ayrıca, piramidin yer aldığı zemin seviyesi ve konumu, onu uzaktan daha yüksek ve etkileyici gösterir.

        Khafre Piramidi’nin iç düzeni, Keops Piramidi’ne benzer şekilde mezar odası ve dar geçitlerden oluşur. Piramidin içindeki mezar odası, firavunun cenaze törenlerinin gerçekleştirildiği ana bölümdür; odanın düzeni ve geçitlerin konumu, firavunun öbür dünyaya geçişine yönelik ritüellerin simgesidir. Ayrıca, piramit kompleksine bağlı mortuary tapınağı ve Vadi Tapınağı, Khafre’nin cenaze inançlarının ve ritüellerinin ayrılmaz parçaları olarak inşa edilmiştir. Kompleks, Büyük Giza Sfenksi ile tamamlanarak firavun için koruyucu bir sembol işlevi görür.

        Eski Mısırlılar için piramitler yalnızca birer mezar yapısı değildi; aynı zamanda firavunların öbür dünyaya geçişlerini, tanrısallaşmalarını ve ebedi yaşamlarını simgeleyen kutsal anıtlardı. Khafre Piramidi, astronomik hizalanmaları ve geometrik oranlarıyla bu inançların somut bir ifadesi olarak öne çıkar. Piramidin düzeni, firavunun ruhunun korunması ve ilahi aleme yükselmesi için hazırlanan ritüel bir mekanizma olarak da yorumlanır.

        Günümüzde gelişmiş arkeolojik yöntemler (lazer tarama, muon görüntüleme, termal analiz gibi) Khafre Piramidi’nin inşaat teknikleri ve iç yapısı hakkında yeni ipuçları ortaya çıkarmaya devam ediyor. Bu teknolojiler, piramidin gizli geçitleri, odalar ve yapı malzemelerinin detaylı analizini mümkün kılmaktadır. Ayrıca, Giza kompleksi, dünya çapında milyonlarca turistin ziyaret ettiği, Mısır ekonomisine büyük katkı sağlayan önemli bir kültürel miras olarak korunmaktadır. Turistler, rehberli turlar ve online bilet sistemleri sayesinde Khafre Piramidi’ni ve çevresindeki diğer antik yapıları güvenle gezebilmektedir.""";
      // MARK: MENKAURE
      case "Ana Bölüm 3":
        return """Giza Platosu’nda yer alan üç büyük piramitten en küçüğü olan Menkaure Piramidi, Mısır’ın antik kraliyet geleneğinin zarif bir ifadesidir. Dördüncü Hanedanlık döneminde, yaklaşık MÖ 2510 civarında tamamlandığı kabul edilen bu piramit, firavun Menkaure’ye (aynı zamanda Mikerinos olarak da bilinir) ithaf edilmiştir. Menkaure, babası Khafre’nin gölgesinde kalmasına rağmen, özenle inşa edilmiş bu anıt, antik Mısır’ın cenaze ritüelleri ve dini inançlarının simgesi olarak öne çıkar.

        Menkaure Piramidi, Giza Platosu’nun güneybatısında, diğer iki dev piramidin (Keops ve Khafre) hemen yanında yer almaktadır. Orijinal yüksekliği yaklaşık 65–66 metre olan piramit, zamanla erozyon ve yağma nedeniyle günümüzde yaklaşık 62 metre yüksekliğe düşmüştür. Taban ölçüleri ise yaklaşık 102 × 104,6 metre olarak belirlenmiştir. Hacmi yaklaşık 235.183 metreküp olan yapı, eğimi yaklaşık 51°20'25'' olarak hesaplanmıştır. Bu ölçüler, Menkaure Piramidi’nin diğer iki piramide kıyasla daha kompakt ve mütevazı yapısını ortaya koyar.

        Menkaure Piramidi, inşasında kireçtaşı, Aswan graniti ve Tura kireçtaşı kullanılarak yükseltilmiştir. Yapının çekirdeğinde kullanılan kireç taşı, üst kısımlarda ise granit ve ince Tura kireçtaşı kaplama tercih edilmiştir. Menkaure’nin ölümü nedeniyle kaplama tamamlanamamış, dış cephede granit bloklardan oluşan katmanlar belirli bir düzene göre yerleştirilmiştir; bu da yapının özgün dokusunu korumasına olanak tanımıştır.

        Diğer Giza piramitlerine benzer şekilde Menkaure Piramidi de, firavunun cenaze odası ve dar geçitlerden oluşan basit bir iç düzene sahiptir. Piramidin içinde, defin odasına giden geçitler ve yan yapılar yer alır. Ayrıca, piramitin yanında yer alan üç küçük kraliçe piramidi, firavuna ait definsel ritüellerin ve ailesine ilişkin anıların izlerini taşır. Bu komplekse bağlı mortuary tapınak ve Vadi Tapınağı, Menkaure’nin ölüm sonrası törenlerinin gerçekleştirildiği alanlar olarak büyük öneme sahiptir.

        Antik Mısır’da piramitler, sadece firavunların mezarları değil, aynı zamanda öbür dünyaya geçişin ve ölümsüzlüğün sembolü olarak inşa edilirdi. Menkaure Piramidi de, firavun Menkaure’nin ebedi istirahat yeri olarak, onun tanrısallaşmasını ve öbür dünya ile olan bağlantısını simgeler. Daha küçük boyutuna rağmen, piramidin geometrik düzeni, astronomik hizalanmaları ve iç süslemeleri, Eski Mısır’ın derin dini inançlarını ve kozmik düzen anlayışını yansıtır.

        Günümüz arkeolojik teknikleri—lazer tarama, termal görüntüleme ve muon taramaları gibi—Menkaure Piramidi’nin inşaat süreci, malzeme kullanımı ve iç yapısı hakkında sürekli yeni bilgiler ortaya çıkarmaktadır. Giza kompleksi, Menkaure Piramidi de dahil olmak üzere, dünya çapında milyonlarca turiste ev sahipliği yaparak Mısır’ın turizm sektöründe önemli bir rol oynar. Turistler, rehberli turlar ve online bilet sistemleri sayesinde bu antik anıtın büyüleyici atmosferini yakından deneyimleyebilirler.

        Menkaure (Mikerinos) Piramidi, Giza Platosu’ndaki üç büyük piramidin en küçüğü olmasına rağmen, Mısır’ın antik kraliyet geleneğinin ve dini ritüellerinin en zarif örneklerinden biridir. Sağlam malzemelerle inşa edilen, özenle düzenlenmiş iç yapısı ve mistik anlamlarıyla bu piramit; firavun Menkaure’nin öbür dünyaya geçiş inancını ve krallığının ebedi sembolünü yansıtır. Modern arkeolojik çalışmalar, bu antik yapının sırlarını gün yüzüne çıkarırken, turizm açısından da Mısır’ın en değerli kültürel miraslarından biri olarak korunmaya devam etmektedir.""";
      // MARK: DJOSER
      case "Ana Bölüm 4":
        return """Djoser Piramidi, Antik Mısır’ın inşa ettiği ilk devasa taş yapı ve aynı zamanda dünyadaki en eski piramit olarak kabul edilir. Sakkara nekropolünde yer alan bu basamaklı piramit, MÖ 27. yüzyılda 3. Hanedanlık döneminde Firavun Djoser için, onun dehası ve ölümsüzlük inancını yansıtmak amacıyla, mimar İmhotep’in öncülüğünde inşa edilmiştir. Yapının benzersiz tasarımı, kare planlı bir mastaba şeklinde başlayan yapının, üzerine eklenen beş mastabanın oluşturduğu altı basamaklı formuyla ortaya çıkmış ve sonrasında Mısır mimarisinde devrim yaratmıştır.

        Djoser Piramidi, orijinal olarak yaklaşık 62,5 metre yüksekliğe sahip olup, 121 metre x 109 metre boyutlarında bir tabana sahiptir. Toplam hacmi yaklaşık 330.400 metreküp olan bu yapı, ince cilalanmış beyaz Tura kireç taşlarıyla kaplanmıştı. Bu özellikleri, piramidi inşa edildiği dönemde Mısır’ın devasa taş mimarisinin başlangıcı haline getirmiştir.

        Djoser Piramidi, basamaklı piramit formunun ortaya çıktığı eşsiz bir projedir. Başlangıçta düz çatılı bir mastaba olarak planlanan yapı, daha sonra ardışık olarak birbirinin üzerine eklenen mastabalar sayesinde altı belirgin basamak şeklinde yükseltilmiştir. Bu aşamalı inşaat süreci, eski Mısırlıların taş blokları kesme, taşıma ve yerleştirme konusundaki üstün mühendislik becerilerinin en çarpıcı örneğini sunar. İmhotep’in yenilikçi yaklaşımı, bu devasa yapının inşasında kullanılan yöntemlerin temelini oluşturmuş ve sonraki piramitlerin inşasında standart haline gelmiştir.

        Piramidin altında, geniş bir yeraltı kompleksi yer alır. Bu karmaşık yapı; firavun Djoser’in cenazesi, aile fertlerinin defni ve değerli mezar eşyalarının saklanması amacıyla inşa edilmiş uzun tünel ve odalar ağından oluşur. Ana mezar odasına inen yaklaşık 28 metrelik bir şaft, devasa bir granit blokla mühürlenmiş; bu uygulama, piramidin koruyucu işlevini pekiştirirken aynı zamanda öbür dünyaya geçiş ritüellerinin sembolü haline gelmiştir.

        Djoser Piramidi, sadece bir mezar olarak değil, aynı zamanda firavun Djoser’in öbür dünyaya geçişini ve ebedi yaşamını garanti altına alan kutsal bir anıt olarak inşa edilmiştir. Piramidin geometrik uyumu, astronomik hizalanmaları ve iç dekoratif unsurları, eski Mısırlıların ölüm sonrası inançlarını ve kraliyet ideolojilerini yansıtır. Bu yapı, ilerleyen dönemlerde inşa edilecek piramitlerin mimari temelini oluşturmuş ve İmhotep’in öncülüğünü Mısır medeniyetinin kalıcı mirası haline getirmiştir.

        Uzun yıllar boyunca çeşitli hava koşulları, erozyon ve yağma çalışmaları nedeniyle zarar gören Djoser Piramidi, 14 yıllık kapsamlı restorasyon çalışmalarının ardından Mart 2020’de yeniden ziyarete açılmıştır. Günümüzde ziyaretçiler, bu antik anıtın özgün dokusunu ve devrim niteliğindeki mimarisini yakından inceleyebilir, aynı zamanda eski Mısır’ın kültürel mirası hakkında derinlemesine bilgi edinebilirler.

        Djoser Piramidi, Antik Mısır’ın taş mimarisinin başlangıcını simgeleyen, devrim niteliğinde bir yapı olarak öne çıkar. İmhotep’in dehasıyla inşa edilen bu basamaklı piramit, hem mimari yenilikleri hem de dini ve kültürel anlamı ile Eski Krallık’ın en önemli miraslarından biridir. Zamanın ötesine uzanan bu yapı, antik firavun inançlarını, ölümsüzlüğü ve kozmik düzeni yansıtarak ziyaretçilerine binlerce yıl öncesine yolculuk yapma imkânı sunmaktadır.""";
      // MARK: BENT
      case "Ana Bölüm 5":
        return """Bent Piramidi, Mısır’ın Dahshur bölgesinde, Kahire’nin yaklaşık 40 km güneyinde yer alan ve 4. Hanedanlık döneminde Firavun Snefru tarafından MÖ 2600’lü yıllarda inşa ettirilen önemli bir yapıdır. Diğer piramitlerden farklı olarak, yapının benzersiz “bükülmüş” görünümü, alt kısmının dik (yaklaşık %54 eğim) ve üst kısmının daha yumuşak (yaklaşık %43 eğim) açıyla yükselmesinden kaynaklanır. İşte bu ani açı değişikliği, piramidin adını “Bent” (eğik) olarak almasına neden olmuştur.

        Bent Piramidi, Dahshur’un geniş, alüvyonlu çölleri üzerinde yükselir. Firavun Snefru, önceki deneyimlerinden (örneğin Meidum Piramidi’nde yaşanan yapısal sorunlardan) ders çıkararak, yapım sürecinde güvenliği sağlamak amacıyla üst kısımdaki eğimi azaltmaya karar vermiştir. Bu stratejik karar, piramidin yapısal istikrarını korumaya yardımcı olmuş ve Snefru’nun mimari mirasının evriminde önemli bir aşama olarak kabul edilmiştir.

        Bent Piramidi, inşasında kullanılan kireç taşı blokları ve ince Tura kireç taşından oluşan kaplamasıyla dikkat çeker. Piramitin alt bölümünde, taş bloklar yaklaşık %54’lük bir açıyla yerleştirilirken, yapının üst kısmı %43’e inen daha yumuşak bir açıyla inşa edilmiştir. Bu ani eğim değişikliği, antik Mısırlıların taş taşımada ve blokları birleştirmede karşılaştıkları zorluklara ve yapısal güvenlik endişelerine yanıt olarak yorumlanır. Bazı araştırmacılar, bu değişikliğin, Meidum Piramidi’nde yaşanan çökme risklerini önlemek amacıyla yapım sırasında kaçınılmaz hale geldiğini öne sürerken, diğerleri geometrik ve estetik faktörlerin belirleyici olduğunu savunmaktadır.

        Bent Piramidi, Snefru’nun inşa ettiği üç piramit arasında bir geçiş modeli olarak görülür. Bu yapı, Eski Mısır’da mezar kültünün evriminde önemli bir mihenk taşıdır. Piramit, sadece firavunun ölüm sonrası ebedi yaşamına geçişinin simgesi değil, aynı zamanda güneş kültü ve kozmik düzenin bir ifadesi olarak da değerlendirilir. Bent Piramidi, sonraki yapılar – özellikle Snefru’nun hemen ardından inşa edilen Kızıl Piramit – için bir deney ve model oluşturmuştur.

        Bent Piramidi, yıllarca çeşitli doğal etkenler ve yağma çalışmaları nedeniyle zarar görmesine rağmen, restorasyon ve koruma çalışmaları sayesinde günümüzde ziyaretçilere açılmıştır. Turistler, piramidin kuzey tarafındaki dar tünelden içeri girerek, yapının iç mekanını ve orijinal inşaat tekniklerini yakından gözlemleme fırsatı bulabilmektedir. Bu eşsiz yapı, antik Mısır’ın mühendislik becerilerinin ve dinî inançlarının canlı bir tanığı olarak turizmde önemli bir yer tutmaktadır.

        Bent Piramidi, antik Mısır’ın inşa ettiği devasa yapılar arasında benzersiz bir yere sahiptir. Firavun Snefru’nun yenilikçi yaklaşımla oluşturduğu bu yapı, inşaat sürecinde karşılaşılan teknik zorluklara pratik bir çözüm getirirken, mimari evrimin de mihenk taşı olmuştur. Yapısal özellikleri, kültürel ve dini anlamları ile Bent Piramidi, hem araştırmacılar hem de tarih meraklıları için eşsiz bir keşif sunmaktadır.""";
      // MARK: MEİDUM
      case "Ana Bölüm 6":
        return """Meidum Piramidi, Antik Mısır piramit mimarisinin evriminde önemli bir ara aşamayı temsil eden erken devasa taş yapılar arasında yer alır. Genellikle Firavun Snefru döneminde inşa edildiği düşünülen bu piramit, başlangıçta basamaklı bir yapı olarak ortaya çıkmış; ancak sonradan düz kenarlı bir piramit formuna dönüştürülmeye çalışılmıştır. Bu dönüşüm sürecinde, yapının üst kısmının büyük bölümünün çökmesiyle günümüze kısmen yıpranmış bir hali ulaşmıştır.

        Meidum Piramidi, Mısır'ın Meidum bölgesinde, Nil Nehri’nin batı kıyısında yer almaktadır. MÖ 2600 civarında inşa edilmiş olduğu tahmin edilen bu yapı, antik Mısır’da piramit inşaat tekniklerindeki deneysel yaklaşımların bir örneğidir. Meidum, diğer piramitlerle karşılaştırıldığında daha erken bir döneme ait olup, mimari yeniliklerin ve geçiş sürecinin önemli bir göstergesidir.

        Meidum Piramidi, başlangıçta basamaklı bir yapı olarak planlanmış; ancak daha sonra düz kenarlı (true pyramid) bir form elde etmek amacıyla dış cepheye ince kaplama taşları uygulanmaya çalışılmıştır. Ne var ki, bu dönüştürme sürecinde yapının üst kısmı büyük ölçüde çökmüş ve günümüzde piramit, iç çekirdek yapısının belirgin olduğu bir formda gözlemlenmektedir. Yapımında kullanılan kireç taşı blokları, antik Mısırlıların taş kesme, taşıma ve yerleştirme konusundaki ustalığını yansıtmaktadır.

        Meidum Piramidi, piramit mimarisinde bir geçiş evresini temsil eder. Basamaklı piramitten düzgün kenarlı piramite geçişte yapılan bu deneysel uygulama, sonraki dönemlerde inşa edilecek Giza piramitlerine temel oluşturacak teknik ve mimari bilgilerin kazanılmasına zemin hazırlamıştır. Meidum’un bu evrimsel aşaması, antik Mısır’ın mühendislik ve planlama becerilerini anlamak açısından arkeologlar ve tarih meraklıları için büyük önem taşımaktadır.

        Meidum Piramidi, yüzyıllar boyunca doğal erozyon, yağma çalışmaları ve çevresel faktörler nedeniyle kısmen çökse de, iç yapısının bazı bölümleri ve kullanılan malzemeler, inşaat tekniklerine dair değerli ipuçları sunmaktadır. Modern arkeolojik ve mühendislik çalışmaları, piramidin orijinal yapısının ve inşaat sürecindeki düzenlemelerin daha iyi anlaşılmasına katkıda bulunarak, Antik Mısır piramitlerinin gelişimindeki rolünü ortaya koymaktadır.

        Meidum Piramidi, antik Mısır piramit mimarisinin evriminde önemli bir dönüm noktası olarak kabul edilir. Başlangıçta basamaklı olarak inşa edilen bu yapı, düz kenarlı piramit formuna geçişte yaşanan deneme ve hatalardan izler taşır. Hem yapısal özellikleri hem de inşaat teknikleri açısından önemli bilgiler sunan Meidum, antik mühendisliğin ve kraliyet mezar mimarisinin erken dönem uygulamalarını anlamak isteyenler için değerli bir örnektir.""";
      // MARK: MEROE
      case "Ana Bölüm 7":
        return """Meroe piramitleri, Sudan’da, eski Kush Krallığı’nın başkenti Meroe çevresinde yer alan ve Afrika’nın en özgün mimari miraslarından biri olarak kabul edilen yapılar grubudur. Geleneksel Mısır piramitlerinden farklı olarak, bu piramitler daha ince, dik ve sivri hatlarıyla dikkat çeker. Antik Kush toplumu, kraliyet ve yüksek rütbeli kişilerin defin işlemleri için bu piramitleri inşa etmiş; böylece ölen kralların ruhlarının ebedi yaşamını garanti altına almayı amaçlamıştır. Yerel kumtaşından inşa edilen piramitler, sıcak renk tonları ve zarif siluetleriyle, eski Kush medeniyetinin mühendislik ve sanatsal ustalığını gözler önüne serer.

        Meroe piramitleri, yaklaşık MÖ 300 ile MS 350 yılları arasına tarihlenen bir döneme ait olup, bölgedeki 200’den fazla mezarlık yapısı içerisinde yer almaktadır. Bu yapılar, Kush Krallığı’nın dini inançlarını, sosyal yapısını ve ölümsüzlük arzusunu yansıtan önemli semboller olarak değerlendirilir. Geleneksel Mısır piramitleriyle kıyaslandığında, Meroe piramitlerinin daha kompakt ve zarif formda olması, yerel kültürün ve inanç sistemlerinin farklılıklarını ortaya koyar.

        Günümüzde, Sudan’daki bu antik yapılar, arkeolojik araştırmalar ve modern turizm çalışmaları sayesinde ziyaretçilere açılmıştır. Bölgeye düzenlenen turlar sayesinde, ziyaretçiler antik Kush Krallığı’nın zengin kültürel geçmişini, dini ritüellerini ve mimari yeniliklerini yerinde gözlem etme imkânı bulur. Meroe piramitleri, hem tarih meraklılarına hem de mimarlık ve arkeoloji alanında çalışan araştırmacılara, Afrika medeniyetinin benzersiz izlerini keşfetme fırsatı sunarak, antik dünyanın derinliklerine yolculuk yapma imkânı sağlamaktadır.""";
      // MARK: GÜNEŞ
      case "Ana Bölüm 8":
        return """Teotihuacan antik kentinde yer alan Güneş Piramidi, Amerika kıtasındaki en büyük piramitlerden biri olarak öne çıkar. Meksika’nın başkenti Mexico City’nin yaklaşık 40 kilometre kuzeydoğusunda bulunan bu antik yapı, UNESCO Dünya Mirası listesinde yer almakta ve kentin mistik atmosferini yansıtan en önemli simgelerden biridir. Güneş Piramidi, adı gibi güneş tanrısına adanmış olup, inşa edildiği dönemde yaşayan toplumun dini ritüelleri ve kozmik düzen anlayışını yansıtır.

        Güneş Piramidi’nin taban alanı yaklaşık 222x225 metre olup, yüksekliği kaynaklara göre 65 ila 70 metre arasında değişmektedir. Bu devasa yapı, volkanik taşlardan inşa edilmiş ve yüzeyi özenle işlenmiş kaplama taşları ile tamamlanmıştır. Yapımında kullanılan teknikler ve devasa taş blokların yerleştirilme yöntemleri, antik Meksika uygarlığının ileri mühendislik bilgisine işaret eder. Güneş Piramidi, Amerika kıtasındaki piramitler arasında üçüncü en yüksek piramit olarak da tanınır.

        Antik Teotihuacan halkı, Güneş Piramidi’ni sadece bir defin yeri olarak değil, aynı zamanda dini ritüellerin gerçekleştirildiği, kozmik düzenin sembolü olan kutsal bir mekan olarak görmüştür. Piramitin çevresinde, Ay Piramidi, Ölüler Yolu ve Quetzalcoatl Tapınağı gibi yapılar yer alır; bu yapıların düzenlenişi, antik toplumun astronomik gözlemleri ve dini inançlarıyla uyumlu bir şekilde planlanmıştır. Teotihuacan’ın bu mistik mimari kompleksi, yüzyıllar boyunca binlerce insanın hayranlıkla ziyaret ettiği ve hala araştırmacılar tarafından incelenen bir antik medeniyetin izlerini taşır.

        Güneş Piramidi, günümüzde modern arkeolojik tekniklerle yapılan detaylı incelemeler sayesinde, hem yapı malzemeleri hem de inşaat yöntemleri hakkında değerli bilgiler sunar. Turistler, antik kentin düzenlenmiş yolları üzerinden piramidin tepesine kadar çıkarak, etrafı saran geniş alanın ve Teotihuacan’ın nefes kesen manzarasının tadını çıkarabilirler. Bu ziyaret, antik uygarlıkların gizemli dünyasına kısa da olsa bir yolculuk yapma fırsatı sunar.""";
      // MARK: TİKAL
      case "Ana Bölüm 9":
        return """Tikal, Guatemala'nın Petén bölgesinde yer alan antik Maya şehridir ve burada bulunan piramitler, Maya medeniyetinin mimari ve astronomik bilgisinin eşsiz örneklerini sunar. Bu antik kentteki piramitler, genellikle tapınak olarak kullanılan yüksek yapılar şeklinde inşa edilmiştir. Özellikle Tikal’in en yüksek yapısı olan ve halk arasında “Tikal Piramidi” olarak da anılan yapı, yaklaşık 70 metre yüksekliğe ulaşır. İnşa edildiği dönemde, geç Klasik dönem Maya uygarlığının önemli ritüellerinin gerçekleştirildiği bu piramit, dini törenlerin yanı sıra, elit sınıfın mezar işlevi de görmek üzere tasarlanmıştır.
          
        Tikal piramitinde, basamaklı platformlar ve geniş merdivenler dikkat çeker; bu merdivenler, ziyaretçilere piramidin tepesine çıkarak etrafı saran yemyeşil orman manzarasını izleme imkânı sunar. Maya mimarisinde sıkça görülen bu yapı düzeni, hem dini inançların hem de kozmik düzenin sembolü olarak yorumlanır. Tikal, uzun yıllar boyunca Maya medeniyetinin siyasi, kültürel ve ekonomik merkezi olarak hizmet vermiş; ancak 9. yüzyılda çeşitli sebeplerden dolayı terk edilmiştir. Günümüzde UNESCO Dünya Mirası listesinde yer alan Tikal, arkeologlar ve tarih meraklıları için hem araştırma konusu hem de ziyaretçilere sunulan benzersiz bir antik kent olarak önemini korumaktadır.
            
        Tikal’in piramitleri, gelişmiş inşaat teknikleri, dikkat çekici astronomik hizalanmaları ve zengin dekoratif unsurlarıyla antik Maya toplumunun yüksek düzeyde organize olduğunu ve derin bir kozmolojik düşünceye sahip olduğunu gözler önüne serer. Ziyaretçiler, Tikal’deki bu görkemli yapıları keşfederken, antik Maya'nın hem yaşam hem de ölüm ritüellerine dair ipuçlarını da yakından gözlemleyebilirler.""";
      // MARK: PALENQUE
      case "Ana Bölüm 10":
        return """Palenque, Meksika’nın Chiapas eyaletinde yer alan antik Maya şehridir ve buradaki piramidal yapılar, Maya medeniyetinin mimari ve kültürel zenginliğini gözler önüne serer. Şehrin en dikkat çekici yapılarından biri olan Yazıtlar Piramidi, 7. yüzyılda inşa edilmiş ve ünlü Maya hükümdarı Pakal’ın mezarını barındırır.

        Bu basamaklı piramit, geniş hiyeroglif panellerle süslenmiş olup, Pakal’ın yaşamı, hükümdarlığı ve dini ritüellerine dair ayrıntılı bilgileri içerir. Yapının tepesindeki tapınak bölümüne çıkan uzun merdivenler, ziyaretçileri piramidin gizemli iç dünyasına ve kraliyet mezarına ulaştırır.

        Zengin taş oymaları, ince süslemeler ve mistik ikonografi, Maya kozmolojisinin, kraliyet ideolojisinin ve inanç sistemlerinin canlı bir yansıması olarak bu yapı, antik dünyanın en etkileyici anıtlarından biri haline gelmiştir.

        Günümüzde UNESCO Dünya Mirası Listesi’nde yer alan Palenque, Yazıtlar Piramidi sayesinde Maya uygarlığının büyüleyici tarihine ve sanatına dair eşsiz ipuçları sunar.""";
      // MARK: CALAKMUL
      case "Ana Bölüm 11":
        return """Calakmul, Meksika'nın Campeche eyaletinde, yoğun tropik ormanların arasında yer alan antik Maya kentlerinden biridir. Bu geniş arkeolojik alan, yaklaşık 70 km²’lik bir bölgeyi kaplamakta ve Maya uygarlığının gücünü, siyasi rekabetini ve zengin kültürel mirasını gözler önüne sermektedir.

        Kentin kalbinde yükselen devasa piramitlerden biri, 45 metreye yakın yüksekliğiyle, Maya mimarisinin en etkileyici örneklerinden sayılır. Calakmul, MÖ 250 ile MS 900 yılları arasında en parlak dönemini yaşamış, Tikal gibi diğer büyük Maya kentleriyle rekabet içinde olmuş ve bölgenin politik gücünü temsil etmiştir.

        UNESCO tarafından 2002 yılında Dünya Mirası Listesi’ne dahil edilen bu antik kent; zengin hiyeroglif yazıtları, heykel ve kabartmalarıyla, Maya toplumunun dini, siyasi ve kültürel yaşamına dair önemli ipuçları sunar. Calakmul, bugün hem arkeologlar hem de tarih meraklıları için Maya uygarlığının derinliklerine yolculuk yapma imkanı sunan eşsiz bir keşif alanıdır.""";
      // MARK: EL CASTİLLO
      case "Ana Bölüm 12":
        return """El Castillo, yaygın olarak Kukulkan Piramidi olarak da bilinir, Meksika’nın Yucatán yarımadasında, Chichén Itzá antik kentinde yer alan ve Maya medeniyetinin en ikonik yapılarından biri olarak kabul edilen devasa bir basamaklı piramit yapısıdır. Bu eşsiz yapı, Maya kültürünün ileri matematik, astronomi ve dini inançlarını yansıtan hem mimari bir başyapıt hem de kozmik düzenin sembolüdür.

        Piramidin her bir yüzü, 91 basamak içerir; en üstte yer alan platform dahil edildiğinde toplam basamak sayısı 365’e ulaşır. Bu sayı, Maya takviminde bir yılın gün sayısına denk gelmesi nedeniyle, El Castillo’nun astronomik ve ritüel anlamda büyük bir öneme sahip olduğunu gösterir. Özellikle bahar ve sonbahar ekinokslarında, piramidin merdivenlerine düşen güneş ışığının yarattığı gölgeler, sanki yılan şeklinde aşağı süzülüyormuş izlenimi verir. Bu optik fenomen, kutsal tüylü yılan tanrısı Kukulkan ile ilişkilendirilir ve Maya inancında yenilenme, doğum ve kozmik döngülerin sembolüdür.

        Yapının inşasında kullanılan büyük kireç taşı blokları, inanılmaz bir mühendislik ve geometrik hesaplamanın ürünü olduğunu gözler önüne serer. Her bir basamağın düzeni ve piramidin genel simetrisi, Maya mimarisinin ne kadar titizlikle planlandığını ve uygulandığını kanıtlar niteliktedir. İnce detaylarla işlenmiş taş oymaları ve hiyeroglif yazıtlar, El Castillo’nun sadece bir anıt değil, aynı zamanda Maya kültürünün tarihini ve mitolojisini anlatan canlı bir belgedir.

        Chichén Itzá’nın merkezi dini ve sosyal yaşam alanının parçası olan El Castillo, antik Maya toplumunda önemli törenlere ev sahipliği yapmıştır. Burada gerçekleştirilen ritüeller, yılın belirli zamanlarında, özellikle ekinoks dönemlerinde, güneşin doğuşu ve batışıyla uyumlu şekilde düzenlenirdi. Bu törenler, toplumun kozmik düzenle olan bağlantısını pekiştirir ve Maya inancının temelini oluşturan yeniden doğuş fikrini simgeler.

        Günümüzde El Castillo, UNESCO Dünya Mirası Listesi’nde yer almakta olup, hem arkeologlar hem de tarih ve kültür meraklıları için eşsiz bir keşif alanı sunar. Sürekli devam eden araştırmalar, piramidin inşa teknikleri, astronomik hizalanmaları ve dinsel sembolizmi hakkında yeni bilgiler ortaya çıkarmakta, böylece antik Maya uygarlığının derin izlerini gün yüzüne çıkarmaktadır.

        El Castillo (Kukulkan Piramidi), Maya medeniyetinin görkemli mirasını, bilimsel ustalığını ve zengin kültürel dokusunu simgeleyen, mimari ve astronomik açıdan son derece etkileyici bir yapıdır. Hem tarih hem de kozmik anlamda taşıdığı derin sembolik değer, bu yapıyı antik dünyanın en büyüleyici anıtlarından biri haline getirmektedir.""";
      // MARK: CESTİUS
      case "Ana Bölüm 13":
        return """Cestius Piramidi, antik Roma'nın kalbinde, Esquilino Tepesi yakınlarında yer alan ve Roma mimarisinin özgün örneklerinden biri olarak dikkat çeker. MÖ 18–12 yılları arasında inşa edilen bu mezar anıtı, ünlü Roma siyasetçisi ve rahip Gaius Cestius Epulo’nun anısına yaptırılmıştır. Piramide di Cestio olarak da bilinen yapı, Mısır piramitlerinden ilham alınarak tasarlanmış, fakat Roma'nın yerel inşaat teknikleri ve estetik anlayışıyla harmanlanmıştır.

        Kare tabanlı ve yaklaşık 27 metre yüksekliğindeki Cestius Piramidi, keskin eğimi (yaklaşık 70 derece) ve orijinalinde beyaz mermer kaplamasıyla öne çıkar. Zamanla mermer kaplamasının bir kısmı yıpransa da, yapının silueti Roma sokaklarında hâlâ belirgin bir iz bırakmaktadır. Bu piramit, Roma'nın Mısır kültürü etkilerini ve İmparatorluk döneminde Batı ile Doğu arasında kurulan kültürel etkileşimin somut bir örneğidir.

        Piramidin inşasında kullanılan malzemeler, dönemin zorluklarına rağmen yüksek mühendislik becerisini yansıtır; tuğla ve mermerin ustaca bir araya getirilmesiyle ortaya konulan yapı, antik Roma'nın lüks mezar mimarisinin tipik bir örneğidir. Cestius Piramidi, hem görsel etkileyiciliği hem de tarihsel önemiyle, antik Roma'nın ölümsüzlük inancını ve elit kesimin kültürel değerlerini yansıtır. Roma'nın modern kentsel dokusu içinde, diğer antik yapılar arasında adeta bir zaman kapsülü gibi duran bu piramit, ziyaretçilerine geçmişin ihtişamını ve antik dünyanın gizemini hatırlatır.

        Bugün Cestius Piramidi, Roma sokaklarında yürürken karşılaşabileceğiniz en etkileyici ve ender görülen anıtlardan biridir. Hem turistlerin hem de tarih ve mimari meraklılarının ilgisini çeken yapı, antik Roma'nın kültürel mirasını ve Doğu-Batı etkileşiminin izlerini günümüze taşıyan eşsiz bir eserdir.""";
      // MARK: CANDİ SUKUH
      case "Ana Bölüm 14":
        return """Candi Sukuh, Endonezya'nın Java Adası'nda, özellikle dağ eteklerinde yer alan ve 15. yüzyılda Majapahit döneminde inşa edildiği düşünülen benzersiz bir tapınaktır. Yerel animistik inançlar ve tantrik öğelerle harmanlanan bu yapı, geleneksel Budist ve Hindu tapınak mimarisinin ötesinde, özgün bir tasarım sunar.

        Piramidal formda yükselen Candi Sukuh, dikdörtgen plana sahip olup, dağ yamacının doğal eğimiyle bütünleşerek çevresiyle uyumlu bir görünüm sergiler. Tapınağın duvarları, erotik figürler, mitolojik semboller ve doğa unsurlarıyla süslenmiş; bu detayların döngüsel yaşam, doğurganlık ve mistik güçler gibi kavramları temsil ettiği düşünülmektedir.

        Bazı akademisyenler, bu görsellerin tapınağın tantrik bir ritüel merkezi olarak işlev gördüğünü ve yerel halkın dini inançlarıyla harmanlanmış özgün bir kültürel sentezi yansıttığını öne sürerken, mimarinin katmanlı yapısı da basamaklı piramit formunu andırarak tapınağa ritüel ve sembolik anlamlar kazandırır.

        Candi Sukuh, hem mimari hem de kültürel açıdan araştırma meraklılarına hitap eden, Endonezya'nın mistik tarihine dair derin ipuçları sunan nadir yapılar arasında yer alır. Turizm ve arkeolojik çalışmalar sayesinde, bu tapınağın gizemli atmosferi günümüzde de ziyaretçilere mistik bir yolculuk deneyimi sunmaktadır.""";
      default:
        return "Bu bölüm hakkında detaylı bilgi.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.only(top: 16, left: 24, right: 24),
      title: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              getTitle(),
              style: GlobalProperties.globalTextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: -15,
            top: -15,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          getContent(),
          style: GlobalProperties.globalTextStyle(),
          textAlign: TextAlign.justify,
          ),
      ),
    );
  }
}

