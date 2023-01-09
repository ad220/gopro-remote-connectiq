/* import Graphics;
import Navigation;
import System;
import Touch;
import VideoParameters;

class MyWidget extends Widget {
  // Variable pour stocker les paramètres vidéo sélectionnés
  var videoParams: VideoParameters;

  function onDraw(dc: Graphics) {
    // Dessine un menu avec les différents paramètres vidéo disponibles
    dc.drawText("Sélectionnez les paramètres vidéo :", 0, 0, dc.getWidth(), dc.getHeight()/5, Graphics.HCenter | Graphics.VTop);
    dc.drawText("Résolution : " + videoParams.resolution.toString(), 0, dc.getHeight()/5, dc.getWidth(), dc.getHeight()/5, Graphics.HCenter | Graphics.VTop);
    dc.drawText("Fréquence d'image : " + videoParams.frameRate.toString(), 0, dc.getHeight()*2/5, dc.getWidth(), dc.getHeight()/5, Graphics.HCenter | Graphics.VTop);
    dc.drawText("Mode de lumière : " + videoParams.lightMode.toString(), 0, dc.getHeight()*3/5, dc.getWidth(), dc.getHeight()/5, Graphics.HCenter | Graphics.VTop);
    dc.drawText("Enregistrer", 0, dc.getHeight()*4/5, dc.getWidth(), dc.getHeight()/5, Graphics.HCenter | Graphics.VTop);
  }

  function onTouch(touch: Touch) {
    // Si c'est un événement "Up", vérifiez si l'utilisateur a appuyé sur une option de menu
    if (touch.type == TouchType.Up) {
      if (touch.y < dc.getHeight()/5) {
        // L'utilisateur a appuyé sur l'en-tête du menu, ignorez-le
      } else if (touch.y < dc.getHeight()*2/5) {
        // L'utilisateur a appuyé sur l'option "Résolution", ouvrez un sous-menu pour sélectionner la résolution souhaitée
        showResolutionMenu();
      } else if (touch.y < dc.getHeight()*3/5) {
        // L'utilisateur a appuyé sur l'option "Fréquence d'image", ouvrez un sous-menu pour sélectionner la fréquence d'image souhaitée
        showFrameRateMenu();
      } else if (touch.y < dc.getHeight()*4/5) {
        // L'utilisateur a appuyé sur l'option "Mode de lumière", ouvrez un sous-menu pour sélectionner le mode de lumière souhaité
        showLightModeMenu();
      } else {
        // L'utilisateur a appuy
 */