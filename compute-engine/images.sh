#!/bin/bash


PUBLIC_IMAGE_URL="http://storage.googleapis.com/swift-worker/a5f622ed31ab1fc1cf59fc7c517100fe9fad9ce7.image.tar.gz"
IMAGE_NAME="swift-worker-image"

# The project id should be passed as argument
add_image_to_project ()
{
    [[ -z "$1" ]] && echo "ERROR: add_image_to_project requires project ID" && return
    gcutil --project=$project_name deleteimage $IMAGE_NAME
    gcutil --project=$project_name addimage $IMAGE_NAME $PUBLIC_IMAGE_URL
}