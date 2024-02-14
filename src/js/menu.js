let visible = false;
let menu = document.getElementById("menu");
let errorOutput = document.getElementById("error-output");

document.getElementById("menu-button").addEventListener("click", function() {
    
    if(visible) {
        menu.style.width = "0";
        errorOutput.style.width = "calc(50% - 1px)";
    }
    else {
        menu.style.width = "150px";
        errorOutput.style.width = "calc(50% + 75px - 1px)";
    }

    visible = !visible;
});

function download(data, filename, type) {

    let file = new Blob([data], {type: type});

    if (window.navigator.msSaveOrOpenBlob) // IE10+
        window.navigator.msSaveOrOpenBlob(file, filename);
    else { // Others
        let a = document.createElement("a"),
        url = URL.createObjectURL(file);

        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();

        setTimeout(function() {
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);  
        }, 0); 
    }
}

// Download
document.getElementById("dowload-li").addEventListener("click", function() {
    download(editor.getValue(), 'fragment.glsl', 'txt');
});

// Uniforms
document.getElementById("uniforms-li").addEventListener("click", function() {
    alert("uniform vec2 u_resolution;\nuniform vec2 u_mouse;\nuniform float u_time;");
});

// Setings
let modalSettings = document.getElementById("settings-modal");
let fontSizeInput = document.getElementById("font-size-input");
let currentFontSize = 12;

// Settings li from menu
document.getElementById("settings-li").addEventListener("click", function() {

    // Load from session storage
    if(localStorage.getItem("FragmentGLSL-font_size") == null) 
        localStorage.setItem("FragmentGLSL-font_size", "12pt");

    currentFontSize = localStorage.getItem("FragmentGLSL-font_size");
    fontSizeInput.value = parseInt(currentFontSize.split('pt')[0]);

    // Display modal window
    modalSettings.style.display = "block";
});

// Close settings
document.getElementById("close-settings").addEventListener("click", function() {

    // Reset editor
    editor.setOptions({
        fontSize: currentFontSize
    });

    // Close modal window
    modalSettings.style.display = "none";
});

// Font input events
fontSizeInput.addEventListener("change", function() {

    let fontSizePt = fontSizeInput.value + "pt";

    editor.setOptions({
        fontSize: fontSizePt
    });
});

// Save button events
document.getElementById("save-settings").addEventListener("click", function() {

    let fontSizePt = fontSizeInput.value + "pt";

    localStorage.setItem("FragmentGLSL-font_size", fontSizePt);

    modalSettings.style.display = "none";
});

// Compile button events
let runButton = document.getElementById("run-button");
runButton.addEventListener("click", function() {

    running = !running;
    
    if(!running) {
        runButton.style.backgroundImage = "url('../img/run.png')";
    }
    else {
        runButton.style.backgroundImage = "url('../img/pause.png')";
    }
});