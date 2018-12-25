{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "2018-12-23";
  name = "font-office-code-pro-${version}";
  at = "ce12a41d6070e545cf2293b2c6fa7c6ef367f29d";

  srcs = [
    (fetchurl {
      url = "https://raw.githubusercontent.com/nathco/Office-Code-Pro/${at}/Fonts/Office%20Code%20Pro%20D/OTF/OfficeCodeProD-Bold.otf";
      name = "office-code-pro-d-bold.otf";
      sha256 = "0lycfsh1ijchknwl550a4r35l7s8mm4nqbq1fw538xjyhzxrw34n";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/nathco/Office-Code-Pro/${at}/Fonts/Office%20Code%20Pro%20D/OTF/OfficeCodeProD-BoldItalic.otf";
      name = "office-code-pro-d-bold-italic.otf";
      sha256 = "1sk2645cdwhm3z3shgsnhb6iiz0dsx861d1l3rg323w7bmlf4r5i";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/nathco/Office-Code-Pro/${at}/Fonts/Office%20Code%20Pro%20D/OTF/OfficeCodeProD-Light.otf";
      name = "office-code-pro-d-light.otf";
      sha256 = "139bb2dvg0xgga48dkxav5adwrm2asxsybbzwg08102r5yaam3rb";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/nathco/Office-Code-Pro/${at}/Fonts/Office%20Code%20Pro%20D/OTF/OfficeCodeProD-LightItalic.otf";
      name = "office-code-pro-d-light-italic.otf";
      sha256 = "04xi1x3v19ylxl4x8z1zyzc4wgbfqx500ly6g0cjgc7k44zfa8gl";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/nathco/Office-Code-Pro/${at}/Fonts/Office%20Code%20Pro%20D/OTF/OfficeCodeProD-Medium.otf";
      name = "office-code-pro-d-medium.otf";
      sha256 = "0q4s1n8ksdwsb0g3s7y8ki69wysj6jdncdnr451j2xjknqd6hk94";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/nathco/Office-Code-Pro/${at}/Fonts/Office%20Code%20Pro%20D/OTF/OfficeCodeProD-MediumItalic.otf";
      name = "office-code-pro-d-medium-italic.otf";
      sha256 = "1bn98gb684ksvzpd4xxmcb1qyqz8xj1ghl1dx6ijxlwirykhgxdh";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/nathco/Office-Code-Pro/${at}/Fonts/Office%20Code%20Pro%20D/OTF/OfficeCodeProD-Regular.otf";
      name = "office-code-pro-d-regular.otf";
      sha256 = "01csxpav3mnnr1ciphqc4q7n9jy2zs7f9jj1mifr6k3ycxhrhdfq";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/nathco/Office-Code-Pro/${at}/Fonts/Office%20Code%20Pro%20D/OTF/OfficeCodeProD-RegularItalic.otf";
      name = "office-code-pro-d-regular-italic.otf";
      sha256 = "1zysm0pl500bcwv6790ypi7jrwxcxwfyk8z9ksjq16yy831i1b7v";
    })
  ];

  phases = [ "unpackPhase" "installPhase" ];

  sourceRoot = "./";

  unpackCmd = ''
    otfName=$(basename $(stripHash $curSrc))
    echo "otfname: $otfName"
    cp $curSrc ./$otfName
  '';

  installPhase = ''
    mkdir -p $out/share/fonts/office-code-pro
    cp *.otf $out/share/fonts/office-code-pro
  '';

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "0cw8vn894sxc17mvi91ddgn3n64n3i3vrfrq8f9mq96qqbb34kfh";

  meta = {
    description = "Office Code Pro Font (patched Source Code Pro Font)";
    homepage = https://github.com/nathco/Office-Code-Pro;
    license = stdenv.lib.licenses.sil;
    platforms = stdenv.lib.platforms.all;
    maintainers = [];
  };
}
