import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;


class ProtuneMenu extends WatchUi.CustomMenu {

    public var ids as ByteArray;

    public function initialize() {
        CustomMenu.initialize(Screen.HEIGHT * 3 / 10, Graphics.COLOR_BLACK,
            { :title => new PickerTitle(Rez.Strings.Protune) });
        
        self.ids = [
            GoProSettings.PROTUNE,
            GoProSettings.WHITE_BL,
            GoProSettings.COLOR,
            GoProSettings.SHARPNESS,
            GoProSettings.EV_COMP,
            GoProSettings.ISO_MAX,
            GoProSettings.ISO_MIN
        ]b;
        var labels = [
            Rez.Strings.Protune,
            Rez.Strings.WhiteBalance,
            Rez.Strings.Color,
            Rez.Strings.Sharpness,
            Rez.Strings.EvComp,
            Rez.Strings.IsoMax,
            Rez.Strings.IsoMin,
        ];
        
        setTitle(new PickerTitle(Rez.Strings.Protune));
        for (var i=0; i<7; i++) {
            var item = new ProtuneMenuItem(ids[i] as GoProSettings.SettingId, labels[i]);
            addItem(item);
        }
    }

    public function onShow() as Void {
        update();
    }

    public function update() as Void {
        for (var i=0; i<mItems.size(); i++) {
            (mItems[i] as ProtuneMenuItem).updateValue();
        }
    }
}