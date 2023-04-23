Config = {
    esx = 'event', -- bruger du en nyere version af esx, så sæt den til 'export' ellers sæt den til 'event'
    Target = 'ft', -- hvis man bruger fivem-target så skriv "ft" ellers bare skriv noget random
    webhook = '', -- webhook hvor alle leasinger osv kommer
    regningerwebhook = '', -- webhook hvor man kan se hvor regninger bliver sendt hen
    returwebhook = '', -- webhook hvor man kan se biler som bliver sendt retur
    bosswebhook = '', -- webhook hvor alle chef handlinger kan ses
    firmanavn = '', -- navnet på firma
    society = '', -- society navn (society_)
    jobname = '', -- jobnavn
    chefgrade = 1, -- hvilken jobgrade skal de have for at tilgå chefmenu
    koblager = 1, -- hvilken jobgrade skal de have for at kunne købe til lageret
    admpersonale = 1, -- hvilken jobgrade skal de have for at kunne administrere personale
    admkasse = 1, -- hvilken jobgrade skal de have for at kunne adminstrere firmakassen
    selglager = 1, -- hvilken jobgrade skal de have for at kunne sælge fra lageret
    skiftydelse = 1, -- hvilken jobgrade skal de have for at kunne skifte ydelse på en bil
    faktura = 1, -- hvilken jobgrade skal de have for at kunne sende en faktura
    t1ger_keys = false, -- gøres der brug af t1ger_keys?
    mf_inventory = false, -- gøres der brug af mf_inventory?
    mellemrum = false, -- er der mellemrum i nummerpladen?
    blip = { -- blip på firmaet
        pos = { 
            x = 222.0758,
            y = -804.3558,
            z = 30.6758
        },
        sprite = 523,
        farve = 4,
        tekst = '' -- hvad skal der stå ved blippen
    },
    katalog = { -- hvor skal man kunne åbne blippen?
        pos = {
            x = 229.1515,
            y = -806.9537,
            z = 30.5096
        }
    },
    spawnleased = { -- hvor skal bilen spawnes når den er blevet leased
        pos = {
            x = 222.0758,
            y = -804.3558,
            z = 30.6758
        },
        h = 202.9733
    },
    spawntry = { -- hvor skal prøvebilerne spawne og kan fjernes
        pos = {
            x = 227.5396,
            y = -792.40175,
            z = 30.6568
        },
        h = 198.1063
    },
    targets = { -- targets
        --[[
            Dette er et eksempel på, hvordan targets skal oprettes:
            [nummer] = {
                pos = {
                    x = 1,
                    y = 2,
                    z = 3,
                }
            },

            Ovenstående skal kopieres ind og tallet skal altid sitge med 1. Ingen af tallene må være det samme.
        --]]
        [1] = {
            x = 222.0758,
            y = -804.3558,
            z = 30.6758
        },
        [2] = {
            x = 227.5396,
            y = -792.40175,
            z = 30.6568
        },
    },
    display = { -- displays
        --[[ 
            Dette er et eksempel på, hvordan man opretter et display køretøj:
            [nummer] = {
                pos = {
                    x = 1,
                    y = 2,
                    z = 3,
                },
                h = 4,
            },

            Ovenstående skal kopieres ind og tallet skal altid stige med 1. Når man opretter et display, så skal man på samme tid oprette en række i databasen også.
            Dette kan man også se på en video
        --]]
        [1] = {
            pos = {
                x = 222.3515,
                y = -786.8694,
                z = 30.7656
            },
            h = 66.4325
        },
    }
}