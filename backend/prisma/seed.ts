import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const monuments = [
  {
    name: 'Zamek Królewski na Wawelu',
    description:
      'Dawna rezydencja królów Polski na wzgórzu nad Wisłą w Krakowie. Renesansowy dziedziniec arkadowy, katedra z grobami monarchów i Dzwon Zygmunta to jedne z najważniejszych symboli polskiej państwowości.',
    latitude: 50.054,
    longitude: 19.9354,
  },
  {
    name: 'Sukiennice w Krakowie',
    description:
      'Renesansowy pasaż handlowy w środku Rynku Głównego, jedna z najstarszych hal targowych w Europie. Na piętrze mieści się Galeria Sztuki Polskiej XIX wieku.',
    latitude: 50.0617,
    longitude: 19.9373,
  },
  {
    name: 'Zamek Królewski w Warszawie',
    description:
      'Odbudowany po zniszczeniach II wojny światowej zamek na Placu Zamkowym. Dawna siedziba królów i władz Rzeczypospolitej, dziś muzeum z kolekcją obrazów Canaletta.',
    latitude: 52.2477,
    longitude: 21.0147,
  },
  {
    name: 'Zamek w Malborku',
    description:
      'Największy gotycki zamek ceglany na świecie, dawna stolica państwa krzyżackiego. Wpisany na listę światowego dziedzictwa UNESCO.',
    latitude: 54.0391,
    longitude: 19.0285,
  },
  {
    name: 'Katedra św. Jana Chrzciciela we Wrocławiu',
    description:
      'Gotycka katedra na Ostrowie Tumskim, jedna z najstarszych świątyń miasta. Po zniszczeniach wojennych została odbudowana, a jej wieże zdobią panoramę Wrocławia.',
    latitude: 51.1148,
    longitude: 17.046,
  },
  {
    name: 'Ratusz Staromiejski we Wrocławiu',
    description:
      'Perła gotyku świeckiego na wrocławskim Rynku. Wnętrza zdobią bogate sklepienia i rzeźbione detale, a w podziemiach działa piwnica świdnicka.',
    latitude: 51.1096,
    longitude: 17.032,
  },
  {
    name: 'Hala Stulecia we Wrocławiu',
    description:
      'Modernistyczna hala widowiskowa projektu Maxa Berga z 1913 roku, wpisana na listę UNESCO. Imponująca żelbetowa kopuła miała w chwili powstania największą rozpiętość na świecie.',
    latitude: 51.1068,
    longitude: 17.077,
  },
  {
    name: 'Bazylika Mariacka w Gdańsku',
    description:
      'Ogromny ceglany kościół gotycki, jeden z największych na świecie. Wewnątrz znajduje się zegar astronomiczny z XV wieku, a z wieży rozciąga się widok na Główne Miasto.',
    latitude: 54.3495,
    longitude: 18.6535,
  },
  {
    name: 'Ratusz Staromiejski w Toruniu',
    description:
      'Gotycki ratusz z wysoką wieżą na Rynku Staromiejskim w Toruniu, mieście urodzin Mikołaja Kopernika. Dziś siedziba Muzeum Okręgowego.',
    latitude: 53.0103,
    longitude: 18.604,
  },
  {
    name: 'Klasztor na Jasnej Górze',
    description:
      'Najważniejsze sanktuarium maryjne w Polsce i cel pielgrzymek z całego kraju. Kaplica Cudownego Obrazu Matki Boskiej Częstochowskiej przyciąga miliony odwiedzających rocznie.',
    latitude: 50.8124,
    longitude: 19.0971,
  },
];

async function main() {
  for (const monument of monuments) {
    await prisma.monument.upsert({
      where: { name: monument.name },
      update: monument,
      create: monument,
    });
  }
  console.log(`Seed zakończony: ${monuments.length} zabytków w bazie.`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
