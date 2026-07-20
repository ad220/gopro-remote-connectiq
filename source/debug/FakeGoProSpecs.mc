import Toybox.Lang;

(:debug)
module FakeGoProSpecs {

    typedef SpecsMap as Dictionary<Number, Dictionary<Number, ByteArray>>;

    typedef ISpecs as interface {
        var cameraId                as Number;
        var availableSettingsMap    as SpecsMap;
        var availableFlicker        as ByteArray;
        var availableHypersmooth    as ByteArray;
        var availableLed            as ByteArray;
        var availableGps            as ByteArray;
    };

    function getSpecsH11M()     as ISpecs { return new SpecsH11Mini(); }
    function getSpecsM1Pro()    as ISpecs { return new SpecsMission1Pro(); }
    function getSpecsH5S()      as ISpecs { return new SpecsH5Session(); }

    class SpecsH11Mini {
        const cameraId = CameraDelegate.GP_HERO11M;

        const availableSettingsMap = {
            26  => {
                GoProSettings.WIDE        => [8,9]b,
            },
            27  => {
                GoProSettings.WIDE        => [8,9,10]b,
                GoProSettings.LINEAR      => [8,9,10]b,
                GoProSettings.LINEARLOCK  => [8,9,10]b,
            },
            100 => {
                GoProSettings.HYPERVIEW   => [8,9,10]b,
                GoProSettings.SUPERVIEW   => [5,6,8,9,10]b,
                GoProSettings.WIDE        => [5,6,8,9,10]b,
                GoProSettings.LINEAR      => [5,6,8,9,10]b,
                GoProSettings.LINEARLOCK  => [8,9,10]b,
                GoProSettings.LINEARLEVEL => [5,6]b,
            },
            28  => {
                GoProSettings.WIDE        => [5,6,8,9]b,
            },
            18  => {
                GoProSettings.WIDE        => [5,6,8,9,10]b,
                GoProSettings.LINEAR      => [5,6,8,9,10]b,
                GoProSettings.LINEARLOCK  => [5,6,8,9,10]b,
            },
            1   => {
                GoProSettings.HYPERVIEW   => [5,6]b,
                GoProSettings.SUPERVIEW   => [1,2,5,6,8,9,10]b,
                GoProSettings.WIDE        => [8,1,10,9,5,2,6]b,
                GoProSettings.LINEAR      => [1,2,5,6,8,9,10]b,
                GoProSettings.LINEARLOCK  => [5,6,8,9,10]b,
                GoProSettings.LINEARLEVEL => [1,2]b,
            },
            6   => {
                GoProSettings.WIDE        => [1,2,5,6]b,
                GoProSettings.LINEAR      => [1,2,5,6]b,
                GoProSettings.LINEARLOCK  => [1,2,5,6]b,
            },
            4   => {
                GoProSettings.SUPERVIEW   => [1,2,5,6]b,
                GoProSettings.WIDE        => [0,1,2,5,6,13]b,
                GoProSettings.LINEAR      => [0,1,2,5,6,13]b,
                GoProSettings.LINEARLOCK  => [1,2,5,6]b,
                GoProSettings.LINEARLEVEL => [0,13]b,
            },
            9   => {
                GoProSettings.SUPERVIEW   => [1,2,5,6,8,9,10]b,
                GoProSettings.WIDE        => [0,1,2,5,6,8,9,10,13]b,
                GoProSettings.LINEAR      => [0,1,2,5,6,8,9,10,13]b,
                GoProSettings.LINEARLOCK  => [1,2,5,6,8,9,10]b,
                GoProSettings.LINEARLEVEL => [0,13]b,
            },
            // 36  => {
            //     GoProSettings.WIDE        => [8,9]b,
            // },
            // 37  => {
            //     GoProSettings.WIDE        => [8,9]b,
            // },
            // 39  => {
            //     GoProSettings.WIDE        => [8,9]b,
            // },
            // 109 => {
            //     GoProSettings.WIDE        => [8,9]b,
            // },
        } as SpecsMap;

        const availableFlicker = [
            GoProSettings.HZ50,
            GoProSettings.HZ60
        ]b;

        const availableLed = [
            GoProSettings.LED_ON,
            GoProSettings.LED_OFF,
            // GoProSettings.LED_ALL_ON,
            // GoProSettings.LED_ALL_OFF,
            // GoProSettings.LED_BACK_ONLY,
        ]b;

        const availableHypersmooth = [
            GoProSettings.HS_OFF,
            GoProSettings.HS_LOW,
            GoProSettings.HS_BOOST,
            GoProSettings.HS_AUTO_BOOST,
        ]b;

        const availableGps = []b;
    }

    class SpecsMission1Pro {
        const cameraId = CameraDelegate.GP_MISSION1PRO;

        const availableSettingsMap = {
            40  => {
                GoProSettings.WIDE        => [8,9,10]b,
                GoProSettings.LINEAR      => [8,9,10]b,
                GoProSettings.LINEARLOCK  => [8,9,10]b,
            },
            31  => {
                GoProSettings.SUPERVIEW   => [5,6,8,9,10]b,
                GoProSettings.WIDE        => [5,6,8,9,10]b,
                GoProSettings.LINEAR      => [8,9,10]b,
                GoProSettings.LINEARLOCK  => [8,9,10]b,
            },
            109 => {
                GoProSettings.WIDE        => [8,9]b,
                GoProSettings.LINEAR      => [8,9]b,
            },
            112 => {
                GoProSettings.WIDE        => [1,2,5,6,8,9,10]b,
                GoProSettings.LINEAR      => [1,2,5,6,8,9,10]b,
                GoProSettings.LINEARLOCK  => [1,2,5,6,8,9,10]b,
            },
            1   => {
                GoProSettings.SUPERVIEW   => [1,2,5,6,8,9,10]b,
                GoProSettings.WIDE        => [0,13,1,2,5,6,8,9,10]b,
                GoProSettings.LINEAR      => [0,13,1,2,5,6,8,9,10]b,
                GoProSettings.LINEARLOCK  => [1,2,5,6,8,9,10]b,
            },
            110 => {
                GoProSettings.WIDE        => [5,6,8,9,10]b,
                GoProSettings.LINEAR      => [5,6,8,9,10]b,
            },
            44  => {
                GoProSettings.WIDE        => [18,15,0,13,1,2,5,6,8,9,10]b,
                GoProSettings.LINEAR      => [18,15,0,13,1,2,5,6,8,9,10]b,
                GoProSettings.LINEARLOCK  => [18,15,0,13,1,2,5,6,8,9,10]b,
            },
            9   => {
                GoProSettings.SUPERVIEW   => [18,15,0,13,1,2,5,6,8,9,10]b,
                GoProSettings.WIDE        => [18,15,0,13,1,2,5,6,8,9,10]b,
                GoProSettings.LINEAR      => [18,15,0,13,1,2,5,6,8,9,10]b,
                GoProSettings.LINEARLOCK  => [18,15,0,13,1,2,5,6,8,9,10]b,
            },
        } as SpecsMap;

        const availableFlicker = [
            GoProSettings.NTSC,
            GoProSettings.PAL
        ]b;

        const availableLed = [
            GoProSettings.LED_ALL_ON,
            GoProSettings.LED_BACK_ONLY,
        ]b;

        const availableHypersmooth = [
            GoProSettings.HS_OFF,
            GoProSettings.HS_LOW,
            GoProSettings.HS_AUTO_BOOST,
        ]b;

        const availableGps = [0, 1]b;
    }

    class SpecsH5Session {
        const cameraId = CameraDelegate.GP_HERO5S;

        const availableSettingsMap = {
            1   => {
                GoProSettings.WIDE        => [8,9]b,
            },
            4   => {
                GoProSettings.WIDE        => [8,9,10]b,
                GoProSettings.MEDIUM      => [7,8,9,10]b,
                GoProSettings.LINEAR      => [8,9,10]b,
            },
            5   => {
                GoProSettings.SUPERVIEW   => [8,9,10]b,
            },
            6   => {
                GoProSettings.WIDE        => [8,9]b,
            },
            7   => {
                GoProSettings.WIDE        => [5,6,7,8,9,10]b,
            },
            8   => {
                GoProSettings.SUPERVIEW   => [5,6,8,9,10]b,
            },
            9   => {
                GoProSettings.WIDE        => [3,5,6,8,9,10]b,
                GoProSettings.MEDIUM      => [8,9,10]b,
                GoProSettings.LINEAR      => [5,6,8,9,10]b,
                GoProSettings.NARROW      => [8,9,10]b,
            },
            10  => {
                GoProSettings.WIDE        => [2,5,6,8,9]b,
            },
            11  => {
                GoProSettings.SUPERVIEW   => [5,6,8,9]b,
            },
            12  => {
                GoProSettings.WIDE        => [1,2,5,6,8,9]b,
                GoProSettings.MEDIUM      => [5,6,8,9]b,
            },
        } as SpecsMap;

        const availableFlicker = [
            GoProSettings.NTSC,
            GoProSettings.PAL
        ]b;

        const availableLed = [
            GoProSettings.LED_OFF,
            GoProSettings.LED_FROFF,
            GoProSettings.LED_ON,
        ]b;

        const availableHypersmooth = [
            GoProSettings.HS_OFF,
            GoProSettings.HS_LOW,
        ]b;

        const availableGps = [0, 1]b;
    }

    class SpecsUnknown {
        const cameraId = CameraDelegate.GP_UNKNOWN;

        const availableSettingsMap    = {
            42  => {
                220     => [20,21,22,28]b,
                221     => [5,6,8,9,10]b,
                222     => [1,5,8]b,
                223     => [2]b,
            },
            69  => {
                72                        => [70,71]b,
                GoProSettings.LINEAR      => [3,6,7]b,
                99                        => [12,46]b,
            },
            27  => {
                50      => [28,230]b,
            }
        } as SpecsMap;
        const availableFlicker        = [10, 210]b;
        const availableHypersmooth    = [52, 63]b;
        const availableLed            = [7, 8]b;
        const availableGps            = [9, 10]b;
    }

    class SpecsEmpty {
        const cameraId                = CameraDelegate.GP_UNKNOWN;
        const availableSettingsMap    = {} as SpecsMap;
        const availableFlicker        = []b;
        const availableHypersmooth    = []b;
        const availableLed            = []b;
        const availableGps            = []b;
    }
}
