//
//  ImageService.swift
//  Imposter
//
//  Production implementation of ImageServiceProtocol.
//  Uses ImagePlayground for AI image generation with caching.
//

import Foundation
import ImagePlayground
import OSLog
import UIKit

// MARK: - ImageService

/// Production image service using Apple's ImagePlayground framework.
/// Provides AI-generated images with memory and disk caching.
final class ImageService: ImageServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.imposter", category: "ImageService")
    private let memoryCache = NSCache<NSString, UIImage>()
    private var _availableStyles: [ImageGenerationStyle] = []
    private var _isAvailable: Bool = false
    private var hasCheckedAvailability = false
    
    /// Directory for persistent image cache
    private let diskCacheDirectory: URL
    
    // MARK: - IP Fallback Mappings
    
    /// Fallback image prompts for movies, TV shows, and anime that Apple Intelligence won't generate directly.
    /// Each mapping provides a relevant, safe visual concept associated with the IP - NO proper nouns allowed.
    private let movieFallbackPrompts: [String: String] = [
        // Easy - Popular Movies & TV
        "wicked": "A sparkling emerald green witch hat with magical sparkles floating around it",
        "moana": "A glowing turquoise heart-shaped stone on ocean waves with tropical hibiscus flowers",
        "deadpool": "Two crossed katana swords in red and black with tacos and chimichangas",
        "inside out": "Colorful glowing emotion orbs - yellow joy, blue sadness, red anger, green disgust, purple fear",
        "despicable me": "Cute yellow pill-shaped creatures wearing blue overalls and silver goggles with bananas",
        "dune": "A giant sandworm emerging from golden desert dunes with orange spice particles floating",
        "beetlejuice": "A black and white vertically striped suit jacket with a carved jack-o-lantern pumpkin",
        "gladiator": "A golden Roman gladiator helmet with red horsehair plume and ancient sword",
        "joker": "A playing card joker with green hair and purple suit design, laughing face",
        "kung fu panda": "A steaming bowl of noodle soup with chopsticks next to bamboo stalks",
        "twisters": "A dramatic gray tornado funnel cloud with debris and storm clouds swirling",
        "squid game": "A pink geometric guard mask with circle, triangle, and square shapes",
        "stranger things": "Colorful Christmas lights on a dark wall spelling letters with an upside-down portal",
        "wednesday": "A gothic severed hand next to a cello and black roses",
        "the bear": "A white chef coat with kitchen knives and a bear paw patch",
        "severance": "A stark white office corridor splitting into two separate paths",
        "shogun": "A samurai katana sword with pink cherry blossom petals and a Japanese castle",
        "fallout": "A retro yellow and blue vault door with a radiation hazard symbol",
        "house of the dragon": "A golden three-headed dragon breathing flames with a crown",
        "the last of us": "A gas mask covered in fungus mushrooms with glowing fireflies",
        "bridgerton": "An elegant Regency-era hand fan with pearls and a golden bee emblem",
        "oppenheimer": "An atomic mushroom cloud explosion with a steel test tower",
        "barbie": "A hot pink convertible car with a pink dreamhouse and sparkles",
        "spider-man": "A red and blue spider web pattern with a black spider in the center",
        "avatar": "Bioluminescent glowing blue alien plants with floating mountains",
        "the avengers": "A collection of hero symbols - round shield, hammer, glowing chest piece, bow and arrows",
        "star wars": "Glowing blue and red laser swords crossed with a spherical space station behind",
        "harry potter": "A wooden magic wand with round glasses and a lightning bolt on a spell book",
        "batman": "A black bat silhouette against a yellow full moon with a dark city skyline",
        "frozen": "A sparkling ice castle with snowflakes and a glowing blue ice crystal",
        "the lion king": "A sunset savanna rock formation with a golden lion paw print",
        "toy story": "A brown cowboy hat next to a white space helmet with stars",
        "finding nemo": "A bright orange clownfish with white stripes, a blue tang fish, and sea anemone",
        "shrek": "A green ogre ear next to a swamp cottage and onion layers",
        "minions": "Yellow capsule-shaped creatures with goggles and blue overalls holding bananas",
        "jurassic park": "A T-Rex dinosaur skeleton silhouette with tropical ferns and a gate",
        "titanic": "A grand ocean liner ship bow in icy waters with a blue diamond necklace",
        "iron man": "A glowing blue circular chest reactor with red and gold metal armor",
        "black panther": "A sleek black panther cat mask with purple glow and tribal patterns",
        "top gun": "Aviator sunglasses with a fighter jet and military patches",
        "john wick": "A gold coin next to a sharp pencil and a black suit",
        "super mario bros": "A red mushroom with white spots, a green pipe, and gold coins",
        "encanto": "A magical glowing wooden door with tropical flowers and butterflies",
        "coco": "A decorated sugar skull with orange marigold flowers and an acoustic guitar",
        
        // Anime - Easy
        "demon slayer": "A green and black checkered pattern robe with a katana and purple wisteria flowers",
        "jujutsu kaisen": "A severed finger in a wooden box with blue mystical flames",
        "attack on titan": "Giant stone fortress walls with wing emblems and thunder spear weapons",
        "my hero academia": "A superhero glove with green lightning sparks and a school badge",
        "one piece": "A woven straw hat with a skull pirate flag and treasure chest",
        "naruto": "An orange spiral symbol with a metal ninja headband and a bowl of ramen",
        "dragon ball": "An orange crystal sphere with stars inside and golden energy aura",
        "pokémon": "A red and white spherical capture ball with yellow mouse ears and lightning bolt",
        "spy x family": "A black tuxedo with a red rose, peanuts, and a stuffed chimera toy",
        "solo leveling": "A dark shadow warrior emerging from a purple portal with twin daggers",
        
        // Anime - Medium
        "chainsaw man": "A chainsaw blade with red devil horns and a necktie",
        "dandadan": "An alien UFO spaceship next to ghostly spirits and dentures",
        "kaiju no 8": "A giant monster reptilian eye with a military defense badge",
        "frieren": "A pointed elf ear with an ancient spell book and a flower-covered magic staff",
        "oshi no ko": "A star-shaped eye pupil with an idol microphone and a ruby gemstone",
        "bocchi the rock": "A pink electric guitar next to a cardboard box hideout",
        "blue lock": "A soccer ball behind blue prison bars with a target crosshair",
        "haikyuu": "A volleyball with orange crow feathers and a gymnasium net",
        "mob psycho": "A percentage counter showing 100% with purple psychic energy explosion",
        "one punch man": "A shiny bald head silhouette with a hero cape and a single red boxing glove",
        "death note": "A black leather notebook with gothic script and a red apple",
        "fullmetal alchemist": "A red hooded coat with a magic transmutation circle and a metal prosthetic arm",
        "hunter x hunter": "A hunter license card with colorful aura energy and playing cards",
        "tokyo revengers": "A black motorcycle gang jacket with a manji symbol emblem",
        "bleach": "A black katana sword with a hollow skull mask and a black robe",
        
        // TV Shows - Medium
        "arcane": "Glowing blue hexagonal crystals with steampunk bronze gears",
        "the penguin": "A black umbrella with a dark city criminal map",
        "agatha all along": "A purple witch cauldron with a winding mystical pathway",
        "nobody wants this": "A prayer shawl next to a podcast microphone",
        "baby reindeer": "A stuffed reindeer plush toy with handwritten letters",
        "true detective": "A detective badge with a swamp landscape and antler crown",
        "euphoria": "Glittery colorful makeup with neon purple lights and a polaroid camera",
        "succession": "A corporate glass skyscraper with a crown and scattered dollar bills",
        "the white lotus": "A white lotus flower floating in a turquoise luxury pool",
        "abbott elementary": "A green classroom chalkboard with school supplies and an apple",
        "only murders": "A podcast microphone with an apartment building and a magnifying glass",
        "ted lasso": "A soccer ball with a handlebar mustache, biscuit tin, and a believe sign",
        "yellowstone": "A cattle ranch branding iron Y with a cowboy hat and mountains",
        "game of thrones": "An iron throne made of swords with dragon eggs",
        "breaking bad": "A chemistry beaker with blue crystals and a yellow hazmat suit",
        "the office": "A ream of white paper with a red stapler in yellow jello",
        "friends": "An orange vintage couch with coffee cups and a gold picture frame",
        
        // Movies - Medium
        "the matrix": "Green falling digital code rain with a red pill and blue pill",
        "inception": "A spinning metal top totem with folding city buildings",
        "the dark knight": "A joker playing card burning with a bat signal in smoke",
        "forrest gump": "A box of assorted chocolates with a white feather and running shoes",
        "the godfather": "Puppet strings on a hand with a red rose and a horse head",
        "pulp fiction": "A glowing golden briefcase with a milkshake and a leather wallet",
        "fight club": "A bar of pink soap with a bruised clenched fist",
        "the shawshank redemption": "Prison cell bars with a rock hammer and a hope poster",
        "back to the future": "A silver sports car with a glowing flux device and a clock tower",
        "indiana jones": "A brown leather fedora hat with a golden idol statue and a bullwhip",
        "pirates of the caribbean": "An antique compass with a black pirate ship and skull flag",
        "the lord of the rings": "A golden ring with elvish script glowing on a fantasy map",
        "the hunger games": "A golden bird pin with an arrow and flames",
        "fast and furious": "A muscle car with a nitrous tank and orange racing flames",
        "mission impossible": "A self-destructing tape recorder with a rappelling rope",
        "home alone": "Paint cans on ropes with aftershave and a house blueprint",
        "mean girls": "A pink diary book with a plastic tiara crown",
        "sonic the hedgehog": "A blue hedgehog silhouette with golden rings and red sneakers",
        "venom": "Black alien tendrils with sharp white eyes and fanged teeth",
        "godzilla": "A giant monster silhouette breathing atomic blue breath on a city",
        "planet of the apes": "A famous statue buried in sand with an ape rubber mask",
        "bad boys": "Police detective badges with a sunset and a sports car",
        
        // Anime - Hard
        "neon genesis evangelion": "A giant purple mecha robot with angel wings and a cross explosion",
        "cowboy bebop": "A red spaceship with a jazz trumpet and a wanted bounty poster",
        "spirited away": "A traditional bathhouse with soot ball spirits and a paper dragon",
        "princess mononoke": "A white wolf god mask with forest spirits and industrial smoke",
        "akira": "A red futuristic motorcycle with a city explosion and a pill capsule",
        "ghost in the shell": "A cybernetic brain with data cables and a neon futuristic city",
        "steins gate": "A banana in a microwave with a digital counter and a white lab coat",
        "vinland saga": "A wooden Viking longship with a battle axe and snowy landscape",
        "monster": "A child's crayon drawing of a scary creature with a beer stein",
        "berserk": "A massive iron greatsword with a red egg talisman and a solar eclipse",
        "your name": "A comet splitting in two over a rural town at twilight",
        "weathering with you": "Rain clouds parting with sunshine rays and praying hands",
        "suzume": "A three-legged wooden chair with a magical cat and a mystical door",
        "the boy and the heron": "A grey heron bird with a fantasy tower and paper airplanes",
        
        // Movies - Hard
        "la la land": "A starry night sky with piano keys and vintage tap dancing shoes",
        "parasite": "A decorative scholar stone with a basement window and a peach",
        "everything everywhere": "A googly-eyed bagel with multiverse portals and hot dog fingers",
        "poor things": "A Victorian laboratory with a brain jar and a ship voyage scene",
        "past lives": "Two origami paper birds separated by an ocean at twilight",
        "killers of the flower moon": "Oil derrick towers with wildflowers and vintage jewelry",
        "the zone of interest": "A garden wall with smoke rising behind and birds singing",
        "american fiction": "A vintage typewriter with rejection letters and stacked books",
        "the holdovers": "A prep school building in snow with a globe and whiskey glass",
        "moonlight": "A moonlit beach scene with blue and purple dramatic lighting",
        "get out": "A teacup being stirred with a dark sunken void below",
        "whiplash": "Wooden drum sticks with blood drops on a snare drum and metronome",
        "blade runner": "A rain-soaked neon city with an origami unicorn and a synthetic eye",
        "the shining": "A long hotel hallway with a room key and a vintage typewriter",
        "psycho": "A motel room key with a shower curtain and taxidermy birds",
        "citizen kane": "A snow globe with a wooden sled and a newspaper printing press",
        "schindler's list": "A small red coat in black and white with a factory worker list",
        "apocalypse now": "Military helicopters over jungle with a fiery sunrise",
        "the silence of the lambs": "A death's head moth with a wine bottle and a census badge",
        "memento": "Scattered polaroid photos with tattoos and backwards handwritten text",
        "eternal sunshine": "A brain being erased with a beach sunset scene",
        "oldboy": "A claw hammer in a long corridor with an octopus and a gift box"
    ]
    
    /// Fallback image prompts for celebrities that Apple Intelligence won't generate (real people).
    /// Each mapping provides an iconic object, symbol, or association - NO proper nouns allowed.
    private let celebrityFallbackPrompts: [String: String] = [
        // Musicians - Easy
        "taylor swift": "Sparkly friendship bracelets with a concert stage and the number 13",
        "beyoncé": "A golden beehive crown with a disco ball and a glass of lemonade",
        "bad bunny": "A sweet bread roll with bunny ears and a microphone",
        "drake": "An owl symbol with a city skyline and champagne bottles",
        "rihanna": "A sparkling diamond with an umbrella and an island flag",
        "sabrina carpenter": "An espresso coffee cup with a blonde hair bow and microphone",
        "chappell roan": "A pink cowgirl hat with theatrical stage makeup and a tiara",
        "billie eilish": "Neon green hair roots on black hair with a spider and baggy clothes",
        "the weeknd": "A red suit jacket with a bandaged face and neon signs",
        "kendrick lamar": "A prestigious award trophy with a crown and a martial arts headband",
        "travis scott": "A cactus logo with a ferris wheel and high-top sneakers",
        "doja cat": "Fuzzy cat ear headband with pink fur and planet motifs",
        "ice spice": "Orange curly hair silhouette with snacks and a corner store",
        "peso pluma": "A wide-brimmed cowboy hat with a double letter logo and a guitar",
        "feid": "A wolf mask with a national flag and a microphone",
        "karol g": "Blue hair with a national flag and a mermaid tail",
        "shakira": "Dancing hip silhouette with a flag and a wolf symbol",
        "dua lipa": "A disco ball with retro album colors and a levitating pose silhouette",
        "ariana grande": "A high ponytail with cat ears and a cloud-shaped perfume bottle",
        "bruno mars": "A fedora hat with a Hawaiian shirt and a gold chain",
        "lady gaga": "A meat dress silhouette with a monster paw print and a disco stick",
        "adele": "A vintage microphone with a tea cup and rolling ocean waves",
        "ed sheeran": "An orange acoustic guitar with a plus sign and ginger hair",
        "justin bieber": "A purple hoodie with a smiley face logo and a maple leaf",
        "post malone": "A face tattoo pattern with beer cans and an acoustic guitar",
        "olivia rodrigo": "A purple driver's license card with a broken heart and grapes",
        "gracie abrams": "Handwritten song lyrics with a vintage camera and emotional teardrops",
        "tyla": "Water dance waves with beaded jewelry and music note symbols",
        "central cee": "A microphone with a city skyline and designer clothing",
        "21 savage": "A knife emoji with an area code and a passport",
        "charli xcx": "A bright green album cover with sound waves and an apple",
        
        // Actors - Easy
        "timothée chalamet": "A chocolate bar with a peach fruit and curly hair silhouette",
        "zendaya": "A spider web pattern with a tennis racket and an award trophy",
        "sydney sweeney": "Glittery makeup with a vintage car and boxing gloves",
        "glen powell": "Aviator pilot sunglasses with a star emblem and a charming smile",
        "florence pugh": "A classic novel book with a tactical vest and a cup of tea",
        "austin butler": "A gold sequined jumpsuit with a motorcycle and a quiff hairstyle",
        "pedro pascal": "A space warrior helmet with a flag and a coffee mug",
        "jenna ortega": "Black braided pigtails with a cello and a gothic dress",
        "barry keoghan": "A luxury bathtub with a traditional ring and an award trophy",
        "tom holland": "A spider mask with a flag and umbrella dancing",
        "ryan gosling": "A plastic doll with piano keys and a maple leaf",
        "margot robbie": "A hot pink logo with a mallet hammer and a national flag",
        "leonardo dicaprio": "An ocean liner ship with an award statue and an environmental globe",
        "dwayne johnson": "A wrestling championship belt with a raised eyebrow and tequila",
        "robert downey jr": "A glowing chest reactor with a detective pipe and an award",
        "keanu reeves": "A sharp pencil with colored pills and a motorcycle",
        
        // Athletes - Easy
        "lebron james": "A royal crown with purple and gold jersey number 23 and a goat",
        "cristiano ronaldo": "A monogram logo with a flag and an iconic goal celebration pose",
        "lionel messi": "A golden trophy with a jersey number 10 and a goat",
        "patrick mahomes": "A championship ring with red team colors and ketchup bottles",
        "travis kelce": "A football jersey number 87 with gloves and friendship bracelets",
        "caitlin clark": "A basketball jersey number 22 with a three-point hand sign and a trophy",
        "simone biles": "Olympic gold medals with a gymnastics leotard and a goat symbol",
        
        // Internet/Business - Easy
        "kim kardashian": "Shapewear clothing with a reality TV camera and law books",
        "kylie jenner": "A lip makeup kit with a social media logo and a letter K",
        "mrbeast": "A video platform play button with chocolate bars and money stacks",
        "kai cenat": "A streaming platform logo with a group logo and gaming setup",
        "ishowspeed": "A soccer ball with an excited expression and a cartoon dog",
        "elon musk": "An electric car with a rocket ship and a social media X logo",
        
        // Musicians - Medium
        "sza": "A life raft with a samurai sword and a butterfly",
        "tyler the creator": "A flower logo with a bee and a blonde wig",
        "lana del rey": "A vintage flag with a cigarette holder and summer melancholy vibes",
        "hozier": "A hymn book with a harp and church architecture",
        "benson boone": "A broken heart symbol with piano keys and a rising star",
        "teddy swims": "A microphone with a soul vinyl record and a full beard",
        "tate mcrae": "A dance pose silhouette with a maple leaf and a pop microphone",
        "dasha": "A cowboy boot with a country music microphone",
        "tommy richman": "A money stack with a funk electric guitar",
        "shaboozey": "A tilted cowboy hat with a microphone and a state outline",
        "sexyy red": "A red wig with an arch landmark and explicit warning label",
        "glorilla": "An orange record label logo with a crown and a rap microphone",
        "latto": "An energy drink can with a peach and a rap crown",
        "cardi b": "A red-soled designer shoe with a bodega cat and a speech bubble",
        "nicki minaj": "A pink chain necklace with a crown and a rap throne",
        "megan thee stallion": "A summer sun with a horse and a city skyline",
        "harry styles": "A fine line tattoo with fruity clothing and a flag",
        "kanye west": "Designer sneakers with a teddy bear mascot and a vest",
        "jay-z": "A diamond hand sign with a bee and a city borough",
        "eminem": "Blonde hair with a highway sign and a rap microphone",
        "snoop dogg": "A gin and juice cocktail with a dog and a marijuana leaf",
        "miley cyrus": "A wrecking ball with a blonde wig and wildflowers",
        
        // Actors - Medium
        "anya taylor-joy": "A chess queen piece with a blonde bob hairstyle and a steering wheel",
        "cillian murphy": "A newsboy flat cap with an atom symbol and a four-leaf clover",
        "paul mescal": "A silver chain necklace with a gladiator sword and a harp",
        "jacob elordi": "A grand mansion with a pompadour hairstyle and a national flag",
        "emma stone": "A yellow vintage dress with an award and a spider web",
        "jennifer lawrence": "A bow and arrow with an award and bourbon whiskey",
        "brad pitt": "A bar of soap with casino dice and a stunt double",
        "angelina jolie": "A humanitarian badge with dual pistols and a glass vial necklace",
        "george clooney": "A martini glass with a coffee capsule and an Italian lake",
        "matt damon": "A spy passport with a potato plant and an accent marker",
        "scarlett johansson": "An hourglass symbol with whiskey and a city at night",
        "chris hemsworth": "A mythical hammer with a surfboard and a national flag",
        "ryan reynolds": "Chimichangas with a gin bottle and a maple leaf",
        "adam sandler": "Basketball shorts with a golf club and a comedy mask",
        "jim carrey": "A green mask face with a tutu and a rubber expression",
        "will smith": "A throne chair with black sunglasses and an award moment",
        "tom hanks": "A box of chocolates with a volleyball named friend and a cowboy hat",
        "morgan freeman": "A narrator microphone with a holy book and freckled skin",
        "denzel washington": "A newspaper prop with vintage glasses and an award statue",
        "samuel l jackson": "A purple laser sword with a leather wallet and a cap hat",
        "meryl streep": "A designer scarf with a collection of award statues",
        
        // Athletes - Medium
        "kylian mbappé": "A rooster symbol with a jersey and a ninja turtle mask celebration",
        "erling haaland": "A viking helmet with blue team colors and a meditation pose",
        "jude bellingham": "A white jersey with a flag and an arms-crossed celebration",
        "neymar": "A yellow jersey with colorful hair and a rainbow kick move",
        "stephen curry": "A blue and gold jersey with a three-point shooting form",
        "kevin durant": "A reaper scythe symbol with team jerseys and a snake",
        "giannis antetokounmpo": "A jersey with a deer antler and sandwich cookies",
        "luka dončić": "A blue jersey with a flag and a stepback move",
        "victor wembanyama": "A black and silver jersey with a baguette and extreme height",
        "shohei ohtani": "A baseball and pitching glove with a samurai sword and blue",
        "connor mcdavid": "An orange jersey with a hockey stick and speed lines",
        "tiger woods": "A golf club with a red shirt and a green jacket",
        "roger federer": "A tennis racket with a monogram logo and chocolate",
        "novak djokovic": "A flag with tennis trophies and a flexible stretch pose",
        "conor mcgregor": "Fighting gloves with a flag and a whiskey bottle",
        "logan paul": "An energy drink with boxing gloves and a video play button",
        "jake paul": "Boxing gloves with a troublemaker logo and a video camera",
        "ksi": "A group logo with boxing gloves and a flag",
        "pokimane": "A streaming logo with a gaming headset and mint tea",
        "addison rae": "A video app logo with a dance pose and beauty products",
        "charli d'amelio": "A dance video app with iced coffee and a heart symbol",
        "alix earle": "A vanity mirror with a video app and a beach sunset",
        
        // Legends - Hard
        "michael jackson": "A white sequined glove with a moonwalk silhouette and a fedora",
        "prince": "A purple rain cloud with a love symbol and an electric guitar",
        "freddie mercury": "A royal crown with a mustache and a microphone pose silhouette",
        "david bowie": "A lightning bolt face paint with a starman and a flag",
        "whitney houston": "A golden microphone with a red rose and a flag",
        "elvis presley": "A white jeweled jumpsuit with lightning and blue suede shoes",
        "bob marley": "A flag with dreadlock hair and a reggae vinyl record",
        "john lennon": "Round circular glasses with a peace sign and piano keys",
        "paul mccartney": "A violin bass guitar with a band logo and knighthood",
        "elton john": "Flamboyant star-shaped glasses with a piano and a rocket",
        "madonna": "A cone bra with a diamond and a dancing pose",
        "britney spears": "A snake with a red jumpsuit and a freedom hashtag",
        "mariah carey": "A Christmas ornament with a butterfly and a high whistle note",
        "celine dion": "An ocean liner ship with a heart and a fleur-de-lis",
        "marlon brando": "Puppet strings on a hand with a leather jacket and an award",
        "al pacino": "A crime boss desk with a red rose and an award statue",
        "robert de niro": "A mohawk hairstyle with a restaurant grill and boxing gloves",
        "jack nicholson": "An axe prop with a sinister grin and dark sunglasses",
        "harrison ford": "A leather whip with a spaceship and a fedora hat",
        "arnold schwarzenegger": "A robotic arm with bodybuilding trophies and a governor seal",
        "tom cruise": "Aviator sunglasses with spy gear and a running pose",
        "audrey hepburn": "A little black dress with a pearl necklace and breakfast pastries",
        "marilyn monroe": "A white dress blowing upward with diamonds and red lipstick",
        "muhammad ali": "Boxing gloves with a bee and butterfly and quick lips",
        "michael jordan": "A jumping silhouette with jersey number 23 and a swoosh",
        "pelé": "A yellow jersey with a world trophy and a bicycle kick",
        "kobe bryant": "A mamba snake with purple jersey number 24 and a memorial",
        "serena williams": "A tennis racket with a bodysuit and a crown of greatness",
        "tom brady": "Championship rings collection with a football and team colors",
        "usain bolt": "A lightning bolt pose with a flag and gold medals",
        "bill gates": "A computer windows logo with a globe and educational books",
        "steve jobs": "A bitten fruit logo with a black turtleneck and a smartphone",
        "mark zuckerberg": "A social network logo with VR goggles and a gray hoodie",
        "jeff bezos": "A smiling arrow logo with a rocket and a bald head silhouette",
        "oprah winfrey": "A talk show couch with a magazine cover and a book club",
        "walt disney": "Round mouse ears with a fantasy castle and animation frames",
        "steven spielberg": "A director's chair with a moon bicycle silhouette and a shark fin",
        "christopher nolan": "A spinning top with a large format camera and a bat signal",
        "martin scorsese": "A movie clapboard with expressive eyebrows and a city skyline",
        "quentin tarantino": "A director's chair with a bandaged foot and film reels"
    ]
    
    // MARK: - Initialization

    init() {
        // Configure memory cache limits
        memoryCache.countLimit = 10
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Setup disk cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDirectory = cacheDir.appendingPathComponent("GeneratedImages", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - ImageServiceProtocol

    var isAvailable: Bool {
        _isAvailable
    }

    var availableStyles: [ImageGenerationStyle] {
        _availableStyles
    }

    var unavailabilityReason: String? {
        if _isAvailable {
            return nil
        }
        return "Image generation is not available on this device"
    }

    func generateImage(
        for word: String,
        category: String,
        style: ImageGenerationStyle?
    ) async throws -> UIImage? {
        logger.debug("Generating image for word: \(word), category: \(category)")

        // Create cache key based on word (normalized)
        let normalizedWord = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let cacheKey = "\(normalizedWord)-\(style?.rawValue ?? "default")" as NSString
        
        // Check memory cache first
        if let cached = memoryCache.object(forKey: cacheKey) {
            logger.debug("Returning memory-cached image for: \(word)")
            return cached
        }
        
        // Check disk cache
        if let diskCached = loadFromDiskCache(key: cacheKey as String) {
            logger.debug("Returning disk-cached image for: \(word)")
            memoryCache.setObject(diskCached, forKey: cacheKey)
            return diskCached
        }

        do {
            // Create ImagePlayground creator
            let creator = try await ImageCreator()

            // Update availability info
            await updateAvailability(from: creator)

            guard !creator.availableStyles.isEmpty else {
                logger.warning("No image styles available")
                throw ImageServiceError.noStylesAvailable
            }

            // Select style
            let playgroundStyle = selectPlaygroundStyle(
                preferred: style,
                available: creator.availableStyles
            )

            // Try generating with primary prompt first
            let imagePrompt = createSafePrompt(for: word, category: category)
            
            if let image = try await attemptGeneration(
                creator: creator,
                prompt: imagePrompt,
                style: playgroundStyle,
                cacheKey: cacheKey
            ) {
                return image
            }
            
            // If that fails, try with a more abstract fallback prompt
            let fallbackPrompt = createFallbackPrompt(for: word, category: category)
            logger.debug("Retrying with fallback prompt: \(fallbackPrompt)")
            
            if let image = try await attemptGeneration(
                creator: creator,
                prompt: fallbackPrompt,
                style: playgroundStyle,
                cacheKey: cacheKey
            ) {
                return image
            }

            logger.warning("No images generated for: \(word)")
            return nil

        } catch let error as ImageServiceError {
            throw error
        } catch {
            logger.error("Image generation failed: \(error.localizedDescription)")
            // Return nil instead of throwing - allows game to continue without image
            return nil
        }
    }
    
    private func attemptGeneration(
        creator: ImageCreator,
        prompt: String,
        style: ImagePlaygroundStyle,
        cacheKey: NSString
    ) async throws -> UIImage? {
        let concepts: [ImagePlaygroundConcept] = [.text(prompt)]
        
        logger.debug("ImagePlayground: Generating image with prompt: '\(prompt)'")
        
        do {
            let imageSequence = creator.images(
                for: concepts,
                style: style,
                limit: 1
            )
            
            for try await generatedImage in imageSequence {
                let uiImage = UIImage(cgImage: generatedImage.cgImage)
                
                // Save to memory cache
                memoryCache.setObject(uiImage, forKey: cacheKey)
                
                // Save to disk cache for persistence
                saveToDiskCache(image: uiImage, key: cacheKey as String)
                
                logger.info("ImagePlayground: Successfully generated and cached image")
                return uiImage
            }
        } catch {
            // Check if it's the person identity error
            let errorString = String(describing: error)
            if errorString.contains("conceptsRequirePersonIdentity") {
                logger.warning("ImagePlayground requires person identity - will try fallback")
                return nil
            }
            throw error
        }
        
        return nil
    }

    func clearCache() {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        if let files = try? FileManager.default.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
        
        logger.debug("Image cache cleared (memory and disk)")
    }
    
    // MARK: - Disk Cache
    
    private func diskCacheURL(for key: String) -> URL {
        // Create a safe filename from the key
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        return diskCacheDirectory.appendingPathComponent("\(safeKey).jpg")
    }
    
    private func loadFromDiskCache(key: String) -> UIImage? {
        let fileURL = diskCacheURL(for: key)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            // Remove corrupted file
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
        
        return image
    }
    
    private func saveToDiskCache(image: UIImage, key: String) {
        let fileURL = diskCacheURL(for: key)
        
        // Compress as JPEG for smaller file size
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            logger.warning("Failed to encode image for disk cache")
            return
        }
        
        do {
            try data.write(to: fileURL)
            logger.debug("Saved image to disk cache: \(key)")
        } catch {
            logger.warning("Failed to save image to disk: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func updateAvailability(from creator: ImageCreator) {
        _isAvailable = true
        _availableStyles = creator.availableStyles.compactMap { playgroundStyle in
            if playgroundStyle == .illustration {
                return .illustration
            } else if playgroundStyle == .animation {
                return .animation
            } else if playgroundStyle == .sketch {
                return .sketch
            } else {
                return nil
            }
        }
        hasCheckedAvailability = true
    }

    private func selectPlaygroundStyle(
        preferred: ImageGenerationStyle?,
        available: [ImagePlaygroundStyle]
    ) -> ImagePlaygroundStyle {
        // Try preferred style first
        if let preferred = preferred {
            switch preferred {
            case .illustration where available.contains(.illustration):
                return .illustration
            case .animation where available.contains(.animation):
                return .animation
            case .sketch where available.contains(.sketch):
                return .sketch
            default:
                break
            }
        }

        // Fall back to priority order - prefer Animation style for fun party game aesthetic
        if available.contains(.animation) {
            return .animation
        } else if available.contains(.illustration) {
            return .illustration
        } else if available.contains(.sketch) {
            return .sketch
        }

        // Use first available
        return available.first ?? .animation
    }

    private func createSafePrompt(for word: String, category: String) -> String {
        // Normalize the word for lookup
        let normalizedWord = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check IP fallback mappings first for movies/TV
        if let moviePrompt = movieFallbackPrompts[normalizedWord] {
            logger.debug("Using movie fallback prompt for: \(word)")
            return "\(moviePrompt), cute cartoon animation style, vibrant colors, no people, no faces"
        }
        
        // Check IP fallback mappings for celebrities
        if let celebrityPrompt = celebrityFallbackPrompts[normalizedWord] {
            logger.debug("Using celebrity fallback prompt for: \(word)")
            return "\(celebrityPrompt), cute cartoon animation style, vibrant colors, no people, no faces"
        }
        
        // Categories that might have people or IP issues - use generic fallbacks
        let sensitiveCategories = ["People", "Celebrities", "Movies", "Movies & TV", "Music", "Sports"]

        if sensitiveCategories.contains(category) {
            // If we don't have a specific mapping, use category-based abstract imagery
            switch category {
            case "People", "Celebrities":
                return "A friendly cartoon character silhouette with sparkles and colorful aura, cute animated style, no real people"
            case "Movies", "Movies & TV":
                return "A cute cartoon movie camera with film reels, sparkly cinema lights, happy popcorn character, no people"
            case "Music":
                return "Happy musical notes dancing in colorful rainbow waves, cute cartoon instruments with faces, no people"
            case "Sports":
                return "Playful cartoon sports equipment bouncing around, dynamic motion lines, bright cheerful colors, no people"
            default:
                return "Cute colorful cartoon shapes representing: \(category), no people, no faces"
            }
        }

        // Safe object-focused prompt - explicitly avoid any person implications
        return "A single \(word) object floating in space, cute cartoon style illustration, no people, no hands, bright colorful background, simple clean design"
    }
    
    private func createFallbackPrompt(for word: String, category: String) -> String {
        // Normalize the word for lookup
        let normalizedWord = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try movie fallback with more abstract styling
        if let moviePrompt = movieFallbackPrompts[normalizedWord] {
            logger.debug("Using movie abstract fallback for: \(word)")
            return "Abstract artistic interpretation: \(moviePrompt), geometric shapes, vibrant colors, cartoon style, absolutely no people or faces"
        }
        
        // Try celebrity fallback with more abstract styling  
        if let celebrityPrompt = celebrityFallbackPrompts[normalizedWord] {
            logger.debug("Using celebrity abstract fallback for: \(word)")
            return "Abstract artistic interpretation: \(celebrityPrompt), geometric shapes, vibrant colors, cartoon style, absolutely no people or faces"
        }
        
        // Ultra-safe abstract prompt that should never require person identity
        return "Abstract colorful geometric shapes and patterns inspired by the concept of '\(category)', vibrant colors, playful design, cartoon illustration style, no people, no faces, no characters"
    }
}
