import Toybox.Lang;

(:debug)
module FakeGoProSpecs {

    typedef SpecsMap as Dictionary<Char or Number, Dictionary<GoProSettings.LensId or Char, Array<Char or Number>>>;

    typedef ISpecs as interface {
        var cameraId                as Number;
        var availableSettingsMap    as SpecsMap;
        var availableFlicker        as Array<Char>;
        var availableHypersmooth    as Array<Char>;
        var availableLed            as Array<Char>;
        var availableGps            as Array<Char>;
    };

    function getSpecsH11M()     as ISpecs { return new SpecsH11Mini(); }
    function getSpecsM1Pro()    as ISpecs { return new SpecsMission1Pro(); }
    function getSpecsH5S()      as ISpecs { return new SpecsH5Session(); }

    class SpecsH11Mini {
        const cameraId = CameraDelegate.GP_HERO11M;

        const availableSettingsMap = {
            26  => {
                GoProSettings.WIDE        => [8,9],
            },
            27  => {
                GoProSettings.WIDE        => [8,9,10],
                GoProSettings.LINEAR      => [8,9,10],
                GoProSettings.LINEARLOCK  => [8,9,10],
            },
            100 => {
                GoProSettings.HYPERVIEW   => [8,9,10],
                GoProSettings.SUPERVIEW   => [5,6,8,9,10],
                GoProSettings.WIDE        => [5,6,8,9,10],
                GoProSettings.LINEAR      => [5,6,8,9,10],
                GoProSettings.LINEARLOCK  => [8,9,10],
                GoProSettings.LINEARLEVEL => [5,6],
            },
            28  => {
                GoProSettings.WIDE        => [5,6,8,9],
            },
            18  => {
                GoProSettings.WIDE        => [5,6,8,9,10],
                GoProSettings.LINEAR      => [5,6,8,9,10],
                GoProSettings.LINEARLOCK  => [5,6,8,9,10],
            },
            1   => {
                GoProSettings.HYPERVIEW   => [5,6],
                GoProSettings.SUPERVIEW   => [1,2,5,6,8,9,10],
                GoProSettings.WIDE        => [8,1,10,9,5,2,6],
                GoProSettings.LINEAR      => [1,2,5,6,8,9,10],
                GoProSettings.LINEARLOCK  => [5,6,8,9,10],
                GoProSettings.LINEARLEVEL => [1,2],
            },
            6   => {
                GoProSettings.WIDE        => [1,2,5,6],
                GoProSettings.LINEAR      => [1,2,5,6],
                GoProSettings.LINEARLOCK  => [1,2,5,6],
            },
            4   => {
                GoProSettings.SUPERVIEW   => [1,2,5,6],
                GoProSettings.WIDE        => [0,1,2,5,6,13],
                GoProSettings.LINEAR      => [0,1,2,5,6,13],
                GoProSettings.LINEARLOCK  => [1,2,5,6],
                GoProSettings.LINEARLEVEL => [0,13],
            },
            9   => {
                GoProSettings.SUPERVIEW   => [1,2,5,6,8,9,10],
                GoProSettings.WIDE        => [0,1,2,5,6,8,9,10,13],
                GoProSettings.LINEAR      => [0,1,2,5,6,8,9,10,13],
                GoProSettings.LINEARLOCK  => [1,2,5,6,8,9,10],
                GoProSettings.LINEARLEVEL => [0,13],
            },
            // 36  => {
            //     GoProSettings.WIDE        => [8,9],
            // },
            // 37  => {
            //     GoProSettings.WIDE        => [8,9],
            // },
            // 39  => {
            //     GoProSettings.WIDE        => [8,9],
            // },
            // 109 => {
            //     GoProSettings.WIDE        => [8,9],
            // },
        } as SpecsMap;

        const availableFlicker = [
            GoProSettings.HZ50,
            GoProSettings.HZ60
        ] as Array<Char>;

        const availableLed = [
            GoProSettings.LED_ON,
            GoProSettings.LED_OFF,
            // GoProSettings.LED_ALL_ON,
            // GoProSettings.LED_ALL_OFF,
            // GoProSettings.LED_BACK_ONLY,
        ] as Array<Char>;

        const availableHypersmooth = [
            GoProSettings.HS_OFF,
            GoProSettings.HS_LOW,
            GoProSettings.HS_BOOST,
            GoProSettings.HS_AUTO_BOOST,
        ] as Array<Char>;

        const availableGps = [] as Array<Char>;
    }

    class SpecsMission1Pro {
        const cameraId = CameraDelegate.GP_MISSION1PRO;

        const availableSettingsMap = {
            40  => {
                GoProSettings.WIDE        => [8,9,10],
                GoProSettings.LINEAR      => [8,9,10],
                GoProSettings.LINEARLOCK  => [8,9,10],
            },
            31  => {
                GoProSettings.SUPERVIEW   => [5,6,8,9,10],
                GoProSettings.WIDE        => [5,6,8,9,10],
                GoProSettings.LINEAR      => [8,9,10],
                GoProSettings.LINEARLOCK  => [8,9,10],
            },
            109 => {
                GoProSettings.WIDE        => [8,9],
                GoProSettings.LINEAR      => [8,9],
            },
            112 => {
                GoProSettings.WIDE        => [1,2,5,6,8,9,10],
                GoProSettings.LINEAR      => [1,2,5,6,8,9,10],
                GoProSettings.LINEARLOCK  => [1,2,5,6,8,9,10],
            },
            1   => {
                GoProSettings.SUPERVIEW   => [1,2,5,6,8,9,10],
                GoProSettings.WIDE        => [0,13,1,2,5,6,8,9,10],
                GoProSettings.LINEAR      => [0,13,1,2,5,6,8,9,10],
                GoProSettings.LINEARLOCK  => [1,2,5,6,8,9,10],
            },
            110 => {
                GoProSettings.WIDE        => [5,6,8,9,10],
                GoProSettings.LINEAR      => [5,6,8,9,10],
            },
            44  => {
                GoProSettings.WIDE        => [18,15,0,13,1,2,5,6,8,9,10],
                GoProSettings.LINEAR      => [18,15,0,13,1,2,5,6,8,9,10],
                GoProSettings.LINEARLOCK  => [18,15,0,13,1,2,5,6,8,9,10],
            },
            9   => {
                GoProSettings.SUPERVIEW   => [18,15,0,13,1,2,5,6,8,9,10],
                GoProSettings.WIDE        => [18,15,0,13,1,2,5,6,8,9,10],
                GoProSettings.LINEAR      => [18,15,0,13,1,2,5,6,8,9,10],
                GoProSettings.LINEARLOCK  => [18,15,0,13,1,2,5,6,8,9,10],
            },
        } as SpecsMap;

        const availableFlicker = [
            GoProSettings.NTSC,
            GoProSettings.PAL
        ] as Array<Char>;

        const availableLed = [
            GoProSettings.LED_ON,
            GoProSettings.LED_BACK_ONLY,
        ] as Array<Char>;

        const availableHypersmooth = [
            GoProSettings.HS_OFF,
            GoProSettings.HS_LOW,
            GoProSettings.HS_AUTO_BOOST,
        ] as Array<Char>;

        const availableGps = [0, 1] as Array<Char>;
    }

    class SpecsH5Session {
        const cameraId = CameraDelegate.GP_HERO5S;

        const availableSettingsMap = {
            1   => {
                GoProSettings.WIDE        => [8,9],
            },
            4   => {
                GoProSettings.WIDE        => [8,9,10],
                GoProSettings.MEDIUM      => [7,8,9,10],
                GoProSettings.LINEAR      => [8,9,10],
            },
            5   => {
                GoProSettings.SUPERVIEW   => [8,9,10],
            },
            6   => {
                GoProSettings.WIDE        => [8,9],
            },
            7   => {
                GoProSettings.WIDE        => [5,6,7,8,9,10],
            },
            8   => {
                GoProSettings.SUPERVIEW   => [5,6,8,9,10],
            },
            9   => {
                GoProSettings.WIDE        => [3,5,6,8,9,10],
                GoProSettings.MEDIUM      => [8,9,10],
                GoProSettings.LINEAR      => [5,6,8,9,10],
                GoProSettings.NARROW      => [8,9,10],
            },
            10  => {
                GoProSettings.WIDE        => [2,5,6,8,9],
            },
            11  => {
                GoProSettings.SUPERVIEW   => [5,6,8,9],
            },
            12  => {
                GoProSettings.WIDE        => [1,2,5,6,8,9],
                GoProSettings.MEDIUM      => [5,6,8,9],
            },
        } as SpecsMap;

        const availableFlicker = [
            GoProSettings.NTSC,
            GoProSettings.PAL
        ] as Array<Char>;

        const availableLed = [
            GoProSettings.LED_OFF,
            GoProSettings.LED_FROFF,
            GoProSettings.LED_ON,
        ] as Array<Char>;

        const availableHypersmooth = [
            GoProSettings.HS_OFF,
            GoProSettings.HS_LOW,
        ] as Array<Char>;

        const availableGps = [0, 1] as Array<Char>;
    }

    class SpecsUnknown {
        const cameraId = CameraDelegate.GP_UNKNOWN;

        const availableSettingsMap    = {
            42  => {
                220     => [20,21,22,28],
                221     => [5,6,8,9,10],
                222     => [1,5,8],
                223     => [2],
            },
            69  => {
                72                        => [70,71],
                GoProSettings.LINEAR      => [3,6,7],
                99                        => [12,46],
            },
            27  => {
                50      => [28,230]
            }
        } as SpecsMap;
        const availableFlicker        = [10, 210] as Array<Char>;
        const availableHypersmooth    = [52, 63] as Array<Char>;
        const availableLed            = [7, 8] as Array<Char>;
        const availableGps            = [9, 10] as Array<Char>;
    }

    class SpecsEmpty {
        const cameraId                = CameraDelegate.GP_UNKNOWN;
        const availableSettingsMap    = {} as SpecsMap;
        const availableFlicker        = [] as Array<Char>;
        const availableHypersmooth    = [] as Array<Char>;
        const availableLed            = [] as Array<Char>;
        const availableGps            = [] as Array<Char>;
    }
}
