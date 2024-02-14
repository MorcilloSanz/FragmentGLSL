let editor = ace.edit("editor");
let darkmodeButton = document.getElementById("darkmode-button");

// Set font size
if(localStorage.getItem("FragmentGLSL-font_size") == null)
    localStorage.setItem("FragmentGLSL-font_size", "12pt");

let fontSizePt = localStorage.getItem("FragmentGLSL-font_size");

// Editor options
editor.setOptions({
    fontSize: fontSizePt
});
editor.setTheme("ace/theme/clouds");
editor.session.setMode("ace/mode/glsl");

// Set dark or light mode
let dark = false;

darkmodeButton.addEventListener("click", function() {
    if(!dark) {
        editor.setTheme("ace/theme/monokai");
        darkmodeButton.style.backgroundImage = "url('img/dark.png')";
    }
    else {
        editor.setTheme("ace/theme/clouds");
        darkmodeButton.style.backgroundImage = "url('img/light.png')";
    }
    dark = !dark;
});