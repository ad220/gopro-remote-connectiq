import Toybox.Lang;

(:debug)
module FakeGoProSpecs {

    typedef SpecsMap as Dictionary<Char or Number, Dictionary<GoProSettings.LensId or Char, Array<Char or Number>>>;

    typedef ISpecs as interface {
        var availableSettingsMap    as SpecsMap;
        var availableFlicker        as Array<Char>;
        var availableHypersmooth    as Array<Char>;
        var availableLed            as Array<Char>;
        var availableGps            as Array<Char>;
    };


    class SpecsH11Mini {
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
                GoProSettings.WIDE        => [1,2,5,6,8,9,10],
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

}
