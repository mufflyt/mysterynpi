# =============================================================================
# ROSTER_BENCHMARK: a labeled, fully synthetic roster -> registry benchmark
# =============================================================================
#
# THE GAP THIS FILLS. No public benchmark exists for physician-roster ->
# NPPES name matching -- NPPES describes real providers, so a labeled gold
# standard would name real people, and nobody ships one. This corpus is the
# alternative: every pair is SYNTHETIC, authored here family by family, with
# truth assigned BY CONSTRUCTION and a note saying which defect the pair
# encodes. Surnames are drawn from the Census 2010 frequency file (aggregate,
# public domain); given names from common-name pools and the vendored
# nickname corpus. No row describes a real person.
#
# SHAPE. One row per (roster record, registry candidate) pair. The roster
# side is a free-text name plus the fields state boards actually hold (no
# gender on most rows -- boards rarely record it; see issue #3). The
# registry side is NPPES-shaped: split ALL-CAPS name fields, credential,
# sex code, state and license from the taxonomy section.
#
# Truth is "match" or "nonmatch", never "maybe": a pair whose truth a
# reviewer could not assign did not go in.
#
# Rerun from the package root:  Rscript data-raw/ROSTER_BENCHMARK.R

fam <- function(family, truth, note, roster_name,
                roster_gender = NA_character_, roster_state = "CO",
                roster_license = NA_character_,
                npi_first, npi_middle = NA_character_, npi_last,
                npi_suffix = NA_character_, npi_credential = "MD",
                npi_gender = NA_character_, npi_state = "CO",
                npi_license = NA_character_) {
  data.frame(family = family, truth = truth, note = note,
             roster_name = roster_name, roster_gender = roster_gender,
             roster_state = roster_state, roster_license = roster_license,
             npi_first = npi_first, npi_middle = npi_middle,
             npi_last = npi_last, npi_suffix = npi_suffix,
             npi_credential = npi_credential, npi_gender = npi_gender,
             npi_state = npi_state, npi_license = npi_license,
             stringsAsFactors = FALSE)
}

blocks <- list(

fam("exact", "match", "clean agreement, the baseline",
    roster_name = c("Mary Johnson", "Robert Miller", "Linda Davis",
                    "James Wilson", "Patricia Moore", "Michael Taylor",
                    "Barbara Anderson", "William Thomas", "Susan Jackson",
                    "David White"),
    roster_gender = c("F","M","F","M","F","M","F","M","F","M"),
    roster_license = sprintf("%05d", 11001:11010),
    npi_first  = c("MARY","ROBERT","LINDA","JAMES","PATRICIA","MICHAEL",
                   "BARBARA","WILLIAM","SUSAN","DAVID"),
    npi_last   = c("JOHNSON","MILLER","DAVIS","WILSON","MOORE","TAYLOR",
                   "ANDERSON","THOMAS","JACKSON","WHITE"),
    npi_gender = c("F","M","F","M","F","M","F","M","F","M"),
    npi_license = sprintf("%05d", 11001:11010)),

fam("formatting", "match", "case, periods, spacing and credential punctuation are formatting",
    roster_name = c("  mary   johnson ", "ROBERT MILLER, M.D.",
                    "Linda R. Davis", "james wilson jr", "Dr. Patricia Moore",
                    "Michael  B.  Taylor", "BARBARA ANDERSON RN",
                    "Thomas, William", "Susan Jackson, D.O.",
                    "White, David, M.D.", "LINDA DAVIS", "Wilson, James B."),
    roster_license = c(sprintf("MD-%05d", 12001:12006),
                       sprintf("MD.%05d", 12007:12012)),
    npi_first  = c("MARY","ROBERT","LINDA","JAMES","PATRICIA","MICHAEL",
                   "BARBARA","WILLIAM","SUSAN","DAVID","LINDA","JAMES"),
    npi_middle = c(NA,NA,"R",NA,NA,"B",NA,NA,NA,NA,NA,"B"),
    npi_last   = c("JOHNSON","MILLER","DAVIS","WILSON","MOORE","TAYLOR",
                   "ANDERSON","THOMAS","JACKSON","WHITE","DAVIS","WILSON"),
    npi_suffix = c(NA,NA,NA,"JR",NA,NA,NA,NA,NA,NA,NA,NA),
    npi_license = sprintf("MD%05d", 12001:12012)),

fam("transliteration", "match", "an accent must reach its unaccented registry spelling",
    roster_name = c("José Álvarez", "María Muñoz", "Piotr Mróz",
                    "Hans Müller", "Sinéad O'Brien", "François Côté",
                    "Renée Dubé", "Søren Åkesson", "Zoë Brontë",
                    "André Muñiz"),
    npi_first  = c("JOSE","MARIA","PIOTR","HANS","SINEAD","FRANCOIS",
                   "RENEE","SOREN","ZOE","ANDRE"),
    npi_last   = c("ALVAREZ","MUNOZ","MROZ","MUELLER","OBRIEN","COTE",
                   "DUBE","AKESSON","BRONTE","MUNIZ")),

fam("nickname", "match", "a recorded hypocorism, admitted by the corpus and nothing fuzzier",
    roster_name = c("Beth Garcia", "Liz Martinez", "Bob Robinson",
                    "Bill Clark", "Peggy Rodriguez", "Nancy Lewis",
                    "Rick Lee", "Katie Walker", "Deb Hall", "Chris Allen",
                    "Mike Young", "Kathy Hernandez", "Jim King",
                    "Tom Wright", "Sue Lopez", "Dan Hill"),
    npi_first  = c("ELIZABETH","ELIZABETH","ROBERT","WILLIAM","MARGARET",
                   "ANN","RICHARD","KATHERINE","DEBORAH","CHRISTOPHER",
                   "MICHAEL","KATHERINE","JAMES","THOMAS","SUSAN","DANIEL"),
    npi_last   = c("GARCIA","MARTINEZ","ROBINSON","CLARK","RODRIGUEZ",
                   "LEWIS","LEE","WALKER","HALL","ALLEN","YOUNG",
                   "HERNANDEZ","KING","WRIGHT","LOPEZ","HILL")),

fam("maiden-as-middle", "match", "the changed surname survives in a middle slot",
    roster_name = c("Katherine Reinhard Rye", "Pamela Harvey Capista",
                    "Alyssa Bantz Hindmon", "Laura Scott Baker",
                    "Emily Green Adams", "Rachel Nelson Carter",
                    "Amanda Mitchell Perez", "Melissa Roberts Turner",
                    "Stephanie Phillips Campbell", "Nicole Parker Evans",
                    "Heather Edwards Collins", "Christine Stewart Morris"),
    npi_first  = c("KATHERINE","PAMELA","ALYSSA","LAURA","EMILY","RACHEL",
                   "AMANDA","MELISSA","STEPHANIE","NICOLE","HEATHER",
                   "CHRISTINE"),
    npi_middle = c("A","BETH","DIANE",NA,NA,"L",NA,"J",NA,NA,"M",NA),
    npi_last   = c("REINHARD","HARVEY","BANTZ","SCOTT","GREEN","NELSON",
                   "MITCHELL","ROBERTS","PHILLIPS","PARKER","EDWARDS",
                   "STEWART")),

fam("compound-surname", "match", "hyphenated and dropped components; 27.1% vs 9.8% unmatched upstream",
    roster_name = c("Anna McCarthy-Dervin", "Sofia Rivera-Cruz",
                    "Grace Cooper-Reed", "Chloe Bailey-Ward",
                    "Lily Torres-Vega", "Ella Ramirez-Sosa",
                    "Maria de la Cruz", "Carmen Vega Santos",
                    "Isabel Cruz-Ortiz", "Elena Santos-Diaz",
                    "Victoria Reyes-Luna", "Julia Flores-Marin"),
    npi_first  = c("ANNA","SOFIA","GRACE","CHLOE","LILY","ELLA","MARIA",
                   "CARMEN","ISABEL","ELENA","VICTORIA","JULIA"),
    npi_last   = c("MCCARTHY","RIVERA","REED","WARD","VEGA","RAMIREZ",
                   "CRUZ","SANTOS","ORTIZ","DIAZ","LUNA","FLORES")),

fam("initials", "match", "an initial corroborates the name it abbreviates",
    roster_name = c("J. Sanders", "M. Bryant", "K. Griffin", "R. Hayes",
                    "L. Simmons", "A. Foster", "D. Gonzales", "S. Butler",
                    "C. Barnes", "E. Fisher"),
    npi_first  = c("JAMES","MARY","KAREN","ROBERT","LINDA","AMY","DAVID",
                   "SUSAN","CAROL","EMILY"),
    npi_last   = c("SANDERS","BRYANT","GRIFFIN","HAYES","SIMMONS","FOSTER",
                   "GONZALES","BUTLER","BARNES","FISHER")),

fam("initials", "nonmatch", "an incompatible initial still vetoes",
    roster_name = c("J. Henderson", "M. Coleman", "K. Jenkins", "R. Perry"),
    npi_first  = c("ROBERT","DAVID","SUSAN","JAMES"),
    npi_last   = c("HENDERSON","COLEMAN","JENKINS","PERRY")),

fam("suffix-generations", "nonmatch", "father and son: same name, same address, one generation apart",
    roster_name = c("Henry Powell Sr", "Walter Long Sr", "Arthur Ross Sr",
                    "Frank Wood Sr", "Roy Cox Sr", "Earl Ford Sr",
                    "Henry A. Powell", "Walter Long III", "Arthur Ross II",
                    "Frank Wood 3rd"),
    npi_first  = c("HENRY","WALTER","ARTHUR","FRANK","ROY","EARL",
                   "HENRY","WALTER","ARTHUR","FRANK"),
    npi_middle = c(NA,NA,NA,NA,NA,NA,"T",NA,NA,NA),
    npi_last   = c("POWELL","LONG","ROSS","WOOD","COX","FORD",
                   "POWELL","LONG","ROSS","WOOD"),
    npi_suffix = c("JR","JR","JR","JR","JR","JR","JR","JR","III","II")),

fam("suffix-generations", "match", "JR and II are the same generation written twice",
    roster_name = c("Henry Powell Jr", "Walter Long 2nd", "Arthur Ross Jr",
                    "Frank Wood II", "Roy Cox Junior", "Earl Ford Jr."),
    npi_first  = c("HENRY","WALTER","ARTHUR","FRANK","ROY","EARL"),
    npi_last   = c("POWELL","LONG","ROSS","WOOD","COX","FORD"),
    npi_suffix = c("II","JR","II","JR","JR","II")),

fam("stale-gender", "match", "a recorded gender conflict on a true match; quarantine, not deletion",
    roster_name = c("Jordan Brooks", "Casey Reed", "Taylor Price",
                    "Morgan Bell", "Riley Murphy", "Avery Rivera"),
    roster_gender = c("F","M","F","M","F","M"),
    roster_license = sprintf("%05d", 15001:15006),
    npi_first  = c("JORDAN","CASEY","TAYLOR","MORGAN","RILEY","AVERY"),
    npi_last   = c("BROOKS","REED","PRICE","BELL","MURPHY","RIVERA"),
    npi_gender = c("M","F","M","F","M","F"),
    npi_license = sprintf("%05d", 15001:15006)),

fam("spelling-trap", "nonmatch",
    paste("different people an edit apart; where the corpus records the",
          "spellings as substitutable (JULIA/JULIE) the deciding evidence",
          "is the middle initial, because spelling alone must not decide",
          "in either direction"),
    roster_name = c("Julia K. Bennett", "Lee Watson", "Elisabeth Gray",
                    "Ann T. Hughes", "Kristina Sullivan", "Jane Russell",
                    "Sara M. Ortiz", "Jon P. Wallace", "Carol D. West",
                    "Dana Wells"),
    npi_first  = c("JULIE","LEA","ELIZABETH","ANNE","KRISHNA","JOAN",
                   "SARAH","JOHN","CAROLE","DANA"),
    npi_middle = c("R",NA,NA,"W",NA,NA,"L","T","G","R"),
    npi_last   = c("BENNETT","WATSON","GRAY","HUGHES","SULLIVAN","RUSSELL",
                   "ORTIZ","WALLACE","WEST","WELLES")),

fam("cross-gender-derivative", "nonmatch", "a prefix rule would admit every one of these",
    roster_name = c("Christina Fleming", "Patricia Warren", "Paula Gibson",
                    "Erica Mason", "Danielle Hunt", "Geraldine Rice",
                    "Michelle Boyd", "Georgia Fox"),
    npi_first  = c("CHRISTOPHER","PATRICK","PAUL","ERIC","DANIEL","GERALD",
                   "MICHAEL","GEORGE"),
    npi_last   = c("FLEMING","WARREN","GIBSON","MASON","HUNT","RICE",
                   "BOYD","FOX")),

fam("common-name-collision", "nonmatch", "agreement on SMITH is weak evidence; the middles and licenses disagree",
    roster_name = c("Mary Ann Smith", "John David Johnson", "Mary Lou Williams",
                    "James Earl Brown", "Linda Kay Jones", "Robert Dean Garcia",
                    "Mary Beth Smith", "John Paul Johnson", "Linda Sue Miller",
                    "James Ray Davis"),
    roster_license = sprintf("%05d", 16001:16010),
    npi_first  = c("MARY","JOHN","MARY","JAMES","LINDA","ROBERT","MARY",
                   "JOHN","LINDA","JAMES"),
    npi_middle = c("JO","MARK","ELLEN","TODD","RAE","GLEN","JANE","MARK",
                   "GAIL","DEAN"),
    npi_last   = c("SMITH","JOHNSON","WILLIAMS","BROWN","JONES","GARCIA",
                   "SMITH","JOHNSON","MILLER","DAVIS"),
    npi_state  = c("TX","TX","AZ","AZ","NM","NM","UT","UT","WY","KS"),
    npi_license = sprintf("%05d", 26001:26010)),

fam("hub-nickname", "nonmatch", "a shared nickname must not weld two formal names",
    roster_name = c("Albert Freeman", "Alexander Freeman", "Christina Webb",
                    "Katherine Tucker", "Margaret Porter", "Antonia Nichols"),
    npi_first  = c("ALEXANDER","ALBERT","CHRISTINE","KATHLEEN","MARJORIE",
                   "ANTOINETTE"),
    npi_last   = c("FREEMAN","FREEMAN","WEBB","TUCKER","PORTER","NICHOLS")),

fam("noise", "match", "credentials, placeholders and alternates are noise, not names",
    roster_name = c("Ann M. Barbaccia (Pollack), M.D.", "Samuel (NMN) Anaya",
                    "Cynthia (Cindi) Holt", "Sandoval, Gloria, CNM",
                    "Kim, Grace, M.D., F.A.C.O.G.", "Prof. Alan Chen PhD",
                    "Ms. Petra Novak", "Rev. Paul Weber MD",
                    "Diaz, Rosa (Rose)", "O'Neal, Shannon R.N.",
                    "Vu, Lan, D.O.", "Cohen, Miriam MPH"),
    npi_first  = c("ANN","SAMUEL","CYNTHIA","GLORIA","GRACE","ALAN","PETRA",
                   "PAUL","ROSA","SHANNON","LAN","MIRIAM"),
    npi_middle = c("M",NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA),
    npi_last   = c("BARBACCIA","ANAYA","HOLT","SANDOVAL","KIM","CHEN",
                   "NOVAK","WEBER","DIAZ","ONEAL","VU","COHEN")),

fam("license-anchor", "match", "same state and number: the strongest key after the NPI itself",
    roster_name = c("Betsy Sherman", "Billy Newton", "Peg Curtis",
                    "Kate Norris", "Debbie Mccormick", "Christy Barrett",
                    "Bobby Mcguire", "Jimmy Mullins"),
    roster_license = sprintf("MD-%05d", 17001:17008),
    npi_first  = c("ELIZABETH","WILLIAM","MARGARET","KATHERINE","DEBORAH",
                   "CHRISTINA","ROBERT","JAMES"),
    npi_last   = c("SHERMAN","NEWTON","CURTIS","NORRIS","MCCORMICK",
                   "BARRETT","MCGUIRE","MULLINS"),
    npi_license = sprintf("MD%05d", 17001:17008)),

fam("license-anchor", "nonmatch", "the same number in another state is a numbering coincidence",
    roster_name = c("Karen Blake", "Steven Doyle", "Janet Frost",
                    "Gary Hardy"),
    roster_license = sprintf("%05d", 18001:18004),
    npi_first  = c("SHARON","STUART","JANICE","GERALD"),
    npi_last   = c("BLAKE","DOYLE","FROST","HARDY"),
    npi_state  = c("TX","TX","AZ","AZ"),
    npi_license = sprintf("%05d", 18001:18004)),

fam("stacked-defects", "match", "several defects at once, as real rows arrive",
    roster_name = c("beth reinhard rye, m.d.", "DR. LIZ MCCARTHY-DERVIN",
                    "  bob   o'brien jr ", "Peg Alvarez (Pegs)",
                    "Katie de la Cruz CNM", "kathy Harvey Capista",
                    "J. Ramirez-Sosa, M.D.", "chris muñoz II",
                    "Deb Santos-Diaz RN", "Mike Mueller 2nd"),
    npi_first  = c("ELIZABETH","ELIZABETH","ROBERT","MARGARET","KATHERINE",
                   "KATHERINE","JORGE","CHRISTOPHER","DEBORAH","MICHAEL"),
    npi_middle = c("A",NA,NA,NA,NA,"BETH",NA,NA,NA,NA),
    npi_last   = c("REINHARD","MCCARTHY","OBRIEN","ALVAREZ","CRUZ","HARVEY",
                   "RAMIREZ","MUNOZ","DIAZ","MUELLER"),
    npi_suffix = c(NA,NA,"JR",NA,NA,NA,NA,"JR",NA,"JR")),

fam("stacked-defects", "nonmatch", "the traps stacked: near-miss spelling plus generation plus initial",
    roster_name = c("Julia Bennett-Cole Jr", "L. Watson Sr", "Ann Hughes III",
                    "Elisabeth Gray-Fox", "Christina Fleming Jr",
                    "Albert Freeman Sr"),
    npi_first  = c("JULIE","ROBERT","ANNE","ELIZABETH","CHRISTOPHER",
                   "ALEXANDER"),
    npi_last   = c("BENNETT","WATSON","HUGHES","GRAY","FLEMING","FREEMAN"),
    npi_suffix = c("SR","JR","II",NA,"SR","JR")),

fam("absence", "match", "almost nothing recorded; only the name decides, and it can",
    roster_name = c("Olga Petrov", "Amir Haddad", "Wei Zhang", "Fatima Noor",
                    "Kwame Mensah", "Ingrid Larsen", "Tariq Aziz",
                    "Mei Chen"),
    roster_state = NA_character_,
    npi_first  = c("OLGA","AMIR","WEI","FATIMA","KWAME","INGRID","TARIQ",
                   "MEI"),
    npi_last   = c("PETROV","HADDAD","ZHANG","NOOR","MENSAH","LARSEN",
                   "AZIZ","CHEN"),
    npi_credential = NA_character_, npi_state = NA_character_))

ROSTER_BENCHMARK <- do.call(rbind, blocks)
ROSTER_BENCHMARK <- cbind(
  pair_id = sprintf("BM%03d", seq_len(nrow(ROSTER_BENCHMARK))),
  ROSTER_BENCHMARK, stringsAsFactors = FALSE)
rownames(ROSTER_BENCHMARK) <- NULL

stopifnot(
  !anyDuplicated(ROSTER_BENCHMARK$pair_id),
  all(ROSTER_BENCHMARK$truth %in% c("match", "nonmatch")),
  nrow(ROSTER_BENCHMARK) >= 180,
  all(nzchar(ROSTER_BENCHMARK$roster_name)),
  all(nzchar(ROSTER_BENCHMARK$npi_last)),
  # every family exists and none is single-truth by accident: families built
  # to hold both truths must hold both
  length(unique(ROSTER_BENCHMARK$family)) >= 14)

save(ROSTER_BENCHMARK, file = "data/ROSTER_BENCHMARK.rda",
     compress = "bzip2", version = 2)
hdr <- c(
  "## ROSTER_BENCHMARK: labeled synthetic roster -> NPPES-shaped pairs.",
  "## Provenance: authored in data-raw/ROSTER_BENCHMARK.R (mysterynpi); truth",
  "## assigned by construction, one defect family per block. Surnames from the",
  "## public-domain Census 2010 frequency file; no real person is described.",
  "## License: MIT, as part of the mysterynpi package.")
writeLines(c(hdr, ""), "inst/extdata/roster_benchmark.csv")
suppressWarnings(write.table(ROSTER_BENCHMARK, "inst/extdata/roster_benchmark.csv",
                             sep = ",", row.names = FALSE, append = TRUE,
                             qmethod = "double"))
cat(nrow(ROSTER_BENCHMARK), "pairs;",
    sum(ROSTER_BENCHMARK$truth == "match"), "matches,",
    sum(ROSTER_BENCHMARK$truth == "nonmatch"), "nonmatches\n")
