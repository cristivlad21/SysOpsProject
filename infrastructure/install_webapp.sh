#!/bin/bash
# install_webapp.sh - User Data Script for EC2 instances

echo "--- Updating packages..."
sudo yum update -y

echo "--- Installing Nginx..."
sudo amazon-linux-extras install nginx1 -y

echo "--- Starting Nginx and enabling it at boot..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Create the index.html file with the JavaScript slideshow
echo "--- Creating index.html..."
sudo tee /usr/share/nginx/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Bamboo Slideshow</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="header-container">
        <h1>Welcome to the Jungle!</h1>
        <p>AWS Infrastructure Project</p>
    </div>
    <div id="slideshow-container">
        <img src="${CLOUDFRONT_IMAGES_BASE_URL}bamboo1.jpg" class="slideshow-img" alt="Bamboo 1">
        <img src="${CLOUDFRONT_IMAGES_BASE_URL}bamboo2.jpg" class="slideshow-img" alt="Bamboo 2">
        <img src="${CLOUDFRONT_IMAGES_BASE_URL}bamboo3.jpg" class="slideshow-img" alt="Bamboo 3">
        <img src="${CLOUDFRONT_IMAGES_BASE_URL}bamboo4.jpg" class="slideshow-img" alt="Bamboo 4">
        <img src="${CLOUDFRONT_IMAGES_BASE_URL}bamboo5.jpg" class="slideshow-img" alt="Bamboo 5">
        <img src="${CLOUDFRONT_IMAGES_BASE_URL}bamboo6.jpg" class="slideshow-img" alt="Bamboo 6">
    </div>
    <script src="script.js"></script>
</body>
</html>
EOF

echo "--- Creating style.css..."
sudo tee /usr/share/nginx/html/style.css <<EOF
body {
    font-family: 'Arial', sans-serif;
    background-color: #e0f2f7;
    color: #333;
    margin: 0;
    padding: 20px;
    display: flex;
    flex-direction: column;
    align-items: center;
    min-height: 100vh;
    box-sizing: border-box;
}
.header-container {
    background-color: #fff;
    padding: 20px 40px;
    border-radius: 10px;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    margin-bottom: 30px;
    text-align: center;
}
h1 {
    color: #2e8b57;
    margin-bottom: 10px;
}
p {
    font-size: 1.1em;
    color: #555;
}
#slideshow-container {
    width: 90%;
    max-width: 900px;
    aspect-ratio: 16 / 9;
    position: relative;
    overflow: hidden;
    border: 8px solid #2e8b57;
    border-radius: 10px;
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
    background-color: #000;
}
#slideshow-container img {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    opacity: 0;
    transition: opacity 1.5s ease-in-out;
}
#slideshow-container img.active {
    opacity: 1;
}
@media (max-width: 768px) {
    .header-container { padding: 15px 20px; }
    h1 { font-size: 1.8em; }
    p { font-size: 0.9em; }
    #slideshow-container { width: 95%; }
}
@media (max-width: 480px) {
    body { padding: 10px; }
    .header-container { padding: 10px 15px; }
    h1 { font-size: 1.5em; }
    p { font-size: 0.8em; }
}
EOF

echo "--- Creating script.js..."
sudo tee /usr/share/nginx/html/script.js <<EOF
document.addEventListener('DOMContentLoaded', () => {
    const images = document.querySelectorAll('.slideshow-img');
    let currentImageIndex = 0;

    function showImage(index) {
        images.forEach((img, i) => {
            img.classList.remove('active');
            if (i === index) {
                img.classList.add('active');
            }
        });
    }

    function showNextImage() {
        currentImageIndex = (currentImageIndex + 1) % images.length;
        showImage(currentImageIndex);
    }

    if (images.length > 0) {
        showImage(currentImageIndex);
    }

    setInterval(showNextImage, 5000);
});
EOF

echo "--- Setting permissions for Nginx..."
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html

echo "--- User Data script completed."