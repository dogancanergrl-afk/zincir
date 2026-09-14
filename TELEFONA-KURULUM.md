# Zincir: Puzzle — telefona alma

İki yol var. İlki hızlı ve tekrar tekrar kullanılır, ikincisi makinene
hiçbir şey kurmadan çalışır.

---

## Yol A — USB ile doğrudan telefona (önerilen)

Bir kez kurarsın, sonra her denemede tek tuş. Geliştirme boyunca
kullanacağın yöntem bu.

### 1. JDK 17 ve Android SDK

```bash
brew install --cask temurin@17
/usr/libexec/java_home -v 17          # çıkan yolu not et
```

Android SDK için https://developer.android.com/studio adresinin en
altındaki **Command line tools only** paketini indir. Android Studio'nun
tamamını kurma, gerek yok.

```bash
mkdir -p ~/Library/Android/sdk/cmdline-tools
# indirdiğin zipin içindeki cmdline-tools klasörünü
# ~/Library/Android/sdk/cmdline-tools/latest olarak taşı

cd ~/Library/Android/sdk/cmdline-tools/latest/bin
./sdkmanager --sdk_root=$HOME/Library/Android/sdk \
  "platform-tools" "build-tools;35.0.1" "platforms;android-35"
./sdkmanager --licenses
```

### 2. Godot'ya yolları tanıt

macOS'ta **Godot > Editor Settings** (Editor menüsü değil), arama kutusuna
`android` yaz:

- **Java SDK Path** → `/usr/libexec/java_home -v 17` çıktısı
- **Android SDK Path** → `/Users/KULLANICI/Library/Android/sdk`

Bir de **Editor > Manage Export Templates > Download and Install**
(yaklaşık 1 GB, bir kez).

### 3. Telefonu hazırla

Ayarlar > Telefon Hakkında > **Yapı Numarası**'na 7 kez bas. Geliştirici
seçenekleri açılır, oradan **USB hata ayıklama**'yı etkinleştir. USB ile
bağla ve telefonda çıkan izin penceresini onayla.

```bash
~/Library/Android/sdk/platform-tools/adb devices
```

Telefonun listede görünüyorsa hazırsın.

### 4. Çalıştır

Godot'nun sağ üstünde telefon ikonu belirir. Tıkla — derler, kurar ve
telefonda açar. Her değişiklikten sonra aynı tuş.

---

## Yol B — GitHub Actions ile bulutta

Makinene hiçbir şey kurmak istemiyorsan. Yavaş (her derleme birkaç
dakika) ama sıfır kurulum.

1. Bu klasörü bir GitHub deposuna yükle.
2. `.github/workflows/android.yml` zaten içinde — push ettiğin anda
   çalışmaya başlar.
3. Depodaki **Actions** sekmesine gir, koşu bitince altındaki
   **Artifacts** bölümünden `zincir-apk` dosyasını indir.
4. APK'yı telefona at (Drive, mail, USB — fark etmez). Telefonda
   açarken "bilinmeyen kaynaklardan yüklemeye izin ver" diyecek, onayla.

---

## Bilmen gerekenler

**Paket adı kalıcıdır.** `export_presets.cfg` içindeki
`package/unique_name` şu an `com.zincirpuzzle.game`. Play Store'a bir
kez yükledikten sonra bu **asla değiştirilemez** — uygulamanın kimliği
budur. Yayınlamadan önce istediğin adı ver.

**Bu APK hata ayıklama sürümüdür.** Kendi telefonunda ve arkadaşlarında
çalışır, Play Store'a yüklenemez. Yayın sürümü için kendi imza anahtarını
üretip Play Console'a yükleyeceksin. O anahtarı kaybedersen uygulamayı
bir daha güncelleyemezsin — yedekle.

**Sadece arm64 derleniyor.** APK'yı küçük tutmak için. 2017 sonrası her
Android telefon arm64. Çok eski bir cihazda denemen gerekirse
`export_presets.cfg` içinde `architectures/armeabi-v7a=true` yap.

**İkon henüz yok.** Godot'nun varsayılan robot ikonuyla geliyor. Kendi
ikonunu yapınca `launcher_icons/` alanlarına bağlarız.

**AdMob ve Play Games için ayar değişecek.** İkisi de
`gradle_build/use_gradle_build=true` istiyor. Şu an `false`, çünkü
Gradle derlemesi daha yavaş ve şimdilik gereksiz. O eklentileri
eklediğimizde açacağız.
