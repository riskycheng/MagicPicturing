#!/bin/bash

# Create directories for images if they don't exist
mkdir -p MagicPicturing/Assets.xcassets/beach.imageset
mkdir -p MagicPicturing/Assets.xcassets/night_sky.imageset
mkdir -p MagicPicturing/Assets.xcassets/mountain.imageset
mkdir -p MagicPicturing/Assets.xcassets/city.imageset
mkdir -p MagicPicturing/Assets.xcassets/flower.imageset
mkdir -p MagicPicturing/Assets.xcassets/concert.imageset

# Download images from Unsplash
echo "Downloading images from Unsplash..."

# Image 1 - Beach (Filter card)
curl -L "https://images.unsplash.com/photo-1500462918059-b1a0cb512f1d?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80" -o MagicPicturing/Assets.xcassets/beach.imageset/beach.jpg

# Image 2 - Night Sky (Grid card)
curl -L "https://images.unsplash.com/photo-1614680376573-df3480f0c6ff?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80" -o MagicPicturing/Assets.xcassets/night_sky.imageset/night_sky.jpg

# Image 3 - Mountain (AI Remove card)
curl -L "https://images.unsplash.com/photo-1619983081563-430f63602796?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80" -o MagicPicturing/Assets.xcassets/mountain.imageset/mountain.jpg

# Image 4 - City (Template card)
curl -L "https://images.unsplash.com/photo-1629276301820-0f3eedc29fd0?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80" -o MagicPicturing/Assets.xcassets/city.imageset/city.jpg

# Image 5 - Flower (Adjust card)
curl -L "https://images.unsplash.com/photo-1598387846148-47e82ee8fcb2?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80" -o MagicPicturing/Assets.xcassets/flower.imageset/flower.jpg

# Image 6 - Concert (Additional image)
curl -L "https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80" -o MagicPicturing/Assets.xcassets/concert.imageset/concert.jpg

echo "Download complete!"
