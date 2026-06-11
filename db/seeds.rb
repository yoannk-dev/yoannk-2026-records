owner = User.find_or_initialize_by(email: "y.kermet@gmail.com")
owner.password = ENV.fetch("SEED_PASSWORD", "changeme123")
owner.save!

records_data = [
  {
    artist: "John Coltrane", title: "Blue Train", year: 1957,
    label: "Blue Note", catalog_number: "BLP 1577", format: "LP, Mono", genre: "Jazz",
    condition: "VG+ / VG", barcode: "724349532717", added_at: "2025-11-02",
    cover_bg: "#0d2c54", cover_fg: "#e8e3d8", cover_motif: "rings",
    tracklist: { "a" => [ "Blue Train", "Moment's Notice" ],
                 "b" => [ "Locomotion", "I'm Old Fashioned", "Lazy Bird" ] }
  },
  {
    artist: "Miles Davis", title: "Kind of Blue", year: 1959,
    label: "Columbia", catalog_number: "CL 1355", format: "LP, Stereo", genre: "Jazz",
    condition: "NM / VG+", barcode: "074646493514", added_at: "2025-11-02",
    cover_bg: "#11151c", cover_fg: "#4a7fa5", cover_motif: "band",
    tracklist: { "a" => [ "So What", "Freddie Freeloader", "Blue in Green" ],
                 "b" => [ "All Blues", "Flamenco Sketches" ] }
  },
  {
    artist: "Joy Division", title: "Unknown Pleasures", year: 1979,
    label: "Factory", catalog_number: "FACT 10", format: "LP", genre: "Rock",
    condition: "VG+ / VG+", barcode: "825646183906", added_at: "2025-11-14",
    cover_bg: "#0a0a0a", cover_fg: "#f2f2f2", cover_motif: "lines",
    tracklist: { "a" => [ "Disorder", "Day of the Lords", "Candidate", "Insight", "New Dawn Fades" ],
                 "b" => [ "She's Lost Control", "Shadowplay", "Wilderness", "Interzone", "I Remember Nothing" ] }
  },
  {
    artist: "Kraftwerk", title: "Trans-Europe Express", year: 1977,
    label: "Kling Klang", catalog_number: "1C 064-82 306", format: "LP", genre: "Electronic",
    condition: "VG / VG", barcode: "5099996602013", added_at: "2025-11-14",
    cover_bg: "#c9c5bd", cover_fg: "#1a1a1a", cover_motif: "diag",
    tracklist: { "a" => [ "Europe Endless", "The Hall of Mirrors", "Showroom Dummies" ],
                 "b" => [ "Trans-Europe Express", "Metal on Metal", "Franz Schubert", "Endless Endless" ] }
  },
  {
    artist: "Stevie Wonder", title: "Songs in the Key of Life", year: 1976,
    label: "Tamla", catalog_number: "T13-340C2", format: "2×LP + 7\"", genre: "Soul",
    condition: "VG+ / VG", barcode: "737463034012", added_at: "2025-11-21",
    cover_bg: "#d96c2c", cover_fg: "#2a1606", cover_motif: "split",
    tracklist: { "a" => [ "Love's in Need of Love Today", "Have a Talk with God", "Village Ghetto Land", "Contusion", "Sir Duke" ],
                 "b" => [ "I Wish", "Knocks Me Off My Feet", "Pastime Paradise", "Summer Soft", "Ordinary Pain" ] }
  },
  {
    artist: "Talking Heads", title: "Remain in Light", year: 1980,
    label: "Sire", catalog_number: "SRK 6095", format: "LP", genre: "Rock",
    condition: "NM / NM", barcode: "075992745710", added_at: "2025-12-03",
    cover_bg: "#b8342a", cover_fg: "#141414", cover_motif: "dots",
    tracklist: { "a" => [ "Born Under Punches", "Crosseyed and Painless", "The Great Curve" ],
                 "b" => [ "Once in a Lifetime", "Houses in Motion", "Seen and Not Seen", "Listening Wind", "The Overload" ] }
  },
  {
    artist: "Aphex Twin", title: "Selected Ambient Works 85–92", year: 1992,
    label: "Apollo", catalog_number: "AMB LP 3922", format: "2×LP", genre: "Electronic",
    condition: "VG+ / VG+", barcode: "5414165070825", added_at: "2025-12-03",
    cover_bg: "#5d6b4e", cover_fg: "#d8d4c5", cover_motif: "circle",
    tracklist: { "a" => [ "Xtal", "Tha", "Pulsewidth" ],
                 "b" => [ "Ageispolis", "Green Calx", "Heliosphan" ] }
  },
  {
    artist: "Marvin Gaye", title: "What's Going On", year: 1971,
    label: "Tamla", catalog_number: "TS 310", format: "LP", genre: "Soul",
    condition: "VG / G+", barcode: "737463031011", added_at: "2025-12-10",
    cover_bg: "#2e4a34", cover_fg: "#d9cfb8", cover_motif: "diag",
    tracklist: { "a" => [ "What's Going On", "What's Happening Brother", "Flyin' High", "Save the Children", "God Is Love", "Mercy Mercy Me" ],
                 "b" => [ "Right On", "Wholy Holy", "Inner City Blues" ] }
  },
  {
    artist: "A Tribe Called Quest", title: "The Low End Theory", year: 1991,
    label: "Jive", catalog_number: "1418-1-J", format: "2×LP", genre: "Hip-Hop",
    condition: "VG+ / VG", barcode: "012414141811", added_at: "2025-12-10",
    cover_bg: "#101010", cover_fg: "#3fae5a", cover_motif: "rings",
    tracklist: { "a" => [ "Excursions", "Buggin' Out", "Rap Promoter", "Butter", "Verses from the Abstract" ],
                 "b" => [ "Check the Rhime", "Jazz (We've Got)", "Scenario" ] }
  },
  {
    artist: "Radiohead", title: "In Rainbows", year: 2007,
    label: "XL Recordings", catalog_number: "XLLP 324", format: "LP", genre: "Rock",
    condition: "NM / NM", barcode: "634904032418", added_at: "2026-01-08",
    cover_bg: "#1c1c1e", cover_fg: "#e8541e", cover_motif: "dots",
    tracklist: { "a" => [ "15 Step", "Bodysnatchers", "Nude", "Weird Fishes/Arpeggi", "All I Need" ],
                 "b" => [ "Faust Arp", "Reckoner", "House of Cards", "Jigsaw Falling into Place", "Videotape" ] }
  },
  {
    artist: "Brian Eno", title: "Ambient 1: Music for Airports", year: 1978,
    label: "Polydor", catalog_number: "AMB 001", format: "LP", genre: "Ambient",
    condition: "VG+ / VG+", barcode: "5099968453015", added_at: "2026-01-08",
    cover_bg: "#e9e6df", cover_fg: "#9aa3a8", cover_motif: "grid",
    tracklist: { "a" => [ "1/1", "2/1" ], "b" => [ "1/2", "2/2" ] }
  },
  {
    artist: "Nina Simone", title: "I Put a Spell on You", year: 1965,
    label: "Philips", catalog_number: "PHM 200-172", format: "LP, Mono", genre: "Jazz",
    condition: "VG / VG", barcode: "042283466418", added_at: "2026-01-19",
    cover_bg: "#4b2e63", cover_fg: "#e7ddca", cover_motif: "type",
    tracklist: { "a" => [ "I Put a Spell on You", "Tomorrow Is My Turn", "Ne Me Quitte Pas", "Marriage Is for Old Folks" ],
                 "b" => [ "Feeling Good", "One September Day", "Blues on Purpose", "Beautiful Land" ] }
  },
  {
    artist: "Daft Punk", title: "Discovery", year: 2001,
    label: "Virgin", catalog_number: "V2940", format: "2×LP", genre: "Electronic",
    condition: "NM / VG+", barcode: "724384960612", added_at: "2026-01-19",
    cover_bg: "#14100c", cover_fg: "#d4af37", cover_motif: "circle",
    tracklist: { "a" => [ "One More Time", "Aerodynamic", "Digital Love" ],
                 "b" => [ "Harder, Better, Faster, Stronger", "Crescendolls", "Nightvision" ] }
  },
  {
    artist: "Fleetwood Mac", title: "Rumours", year: 1977,
    label: "Warner Bros.", catalog_number: "BSK 3010", format: "LP", genre: "Rock",
    condition: "VG / VG", barcode: "075992731317", added_at: "2026-02-02",
    cover_bg: "#ece4d4", cover_fg: "#3c3528", cover_motif: "split",
    tracklist: { "a" => [ "Second Hand News", "Dreams", "Never Going Back Again", "Don't Stop", "Go Your Own Way", "Songbird" ],
                 "b" => [ "The Chain", "You Make Loving Fun", "I Don't Want to Know", "Oh Daddy", "Gold Dust Woman" ] }
  },
  {
    artist: "Nas", title: "Illmatic", year: 1994,
    label: "Columbia", catalog_number: "C 57684", format: "LP", genre: "Hip-Hop",
    condition: "VG+ / VG+", barcode: "074645768410", added_at: "2026-02-02",
    cover_bg: "#8c6f4e", cover_fg: "#1d160e", cover_motif: "band",
    tracklist: { "a" => [ "The Genesis", "N.Y. State of Mind", "Life's a Bitch", "The World Is Yours", "Halftime" ],
                 "b" => [ "Memory Lane", "One Love", "One Time 4 Your Mind", "Represent", "It Ain't Hard to Tell" ] }
  },
  {
    artist: "Portishead", title: "Dummy", year: 1994,
    label: "Go! Beat", catalog_number: "828 522-1", format: "LP", genre: "Electronic",
    condition: "VG+ / VG", barcode: "042282852212", added_at: "2026-03-15",
    cover_bg: "#23262a", cover_fg: "#aeb6bd", cover_motif: "circle",
    tracklist: { "a" => [ "Mysterons", "Sour Times", "Strangers", "It Could Be Sweet", "Wandering Star" ],
                 "b" => [ "Numb", "Roads", "Pedestal", "Biscuit", "Glory Box" ] }
  },
  {
    artist: "Sade", title: "Diamond Life", year: 1984,
    label: "Epic", catalog_number: "EPC 26044", format: "LP", genre: "Soul",
    condition: "NM / NM", barcode: "5099702604413", added_at: "2026-03-15",
    cover_bg: "#101010", cover_fg: "#c8a24b", cover_motif: "band",
    tracklist: { "a" => [ "Smooth Operator", "Your Love Is King", "Hang On to Your Love" ],
                 "b" => [ "Frankie's First Affair", "When Am I Going to Make a Living", "Cherry Pie", "Sally", "Why Can't We Live Together" ] }
  },
  {
    artist: "Can", title: "Tago Mago", year: 1971,
    label: "United Artists", catalog_number: "UAS 29 211/12", format: "2×LP", genre: "Rock",
    condition: "VG / G+", barcode: "5099990584817", added_at: "2026-04-01",
    cover_bg: "#d4541f", cover_fg: "#19100a", cover_motif: "rings",
    tracklist: { "a" => [ "Paperhouse", "Mushroom", "Oh Yeah" ], "b" => [ "Halleluhwah" ] }
  }
]

records_data.each do |data|
  label = Label.find_or_create_by!(name: data[:label])
  record = Record.find_or_initialize_by(artist: data[:artist], title: data[:title])
  record.assign_attributes(
    label: label,
    year: data[:year],
    format: data[:format],
    genre: data[:genre],
    catalog_number: data[:catalog_number],
    barcode: data[:barcode],
    cover_bg: data[:cover_bg],
    cover_fg: data[:cover_fg],
    cover_motif: data[:cover_motif],
    tracklist: data[:tracklist]
  )
  record.save!

  UserRecord.find_or_create_by!(user: owner, record: record) do |ur|
    ur.condition = data[:condition]
    ur.added_at  = Date.parse(data[:added_at])
  end
end

puts "Seeded #{Record.count} records for #{owner.email}"
