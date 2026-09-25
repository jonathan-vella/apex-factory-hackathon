# Teaching Material Image Upload Feature

This feature allows administrators to upload images for teaching materials (textbooks) associated with courses.

## Features

- **Image Upload**: Upload teaching material images when creating or editing courses
- **File Validation**: Supports JPG, JPEG, PNG, GIF, and BMP formats
- **Size Limits**: Maximum file size of 5MB per image
- **Storage**: Images are stored under `wwwroot/Uploads/TeachingMaterials/`
- **Automatic Cleanup**: Images are automatically deleted when courses are removed
- **Unique Filenames**: Each uploaded image gets a unique filename to prevent conflicts

## Usage

### Creating a Course with Teaching Material Image

1. Navigate to the Courses section
2. Click "Create New" (Admin only)
3. Fill in the course details
4. In the "Teaching Material Image" section, click "Choose File"
5. Select an image file (JPG, JPEG, PNG, GIF, or BMP)
6. Click "Create" to save the course

### Editing a Course's Teaching Material Image

1. Navigate to the Courses section
2. Click "Edit" next to the course you want to modify
3. If a teaching material image already exists, it will be displayed
4. To change the image, click "Choose File" and select a new image
5. Click "Save" to update the course

### Viewing Teaching Material Images

- **Course List**: Small thumbnails (50x50px) are displayed in the courses index
- **Course Details**: Full-size images (max 300x300px) are displayed on the course details page

## Technical Details

### File Storage
- Images are stored in `wwwroot/Uploads/TeachingMaterials/` and served at
  `/Uploads/TeachingMaterials/`
- Filenames follow the pattern: `course_{CourseID}_{GUID}.{extension}`
- Old images are automatically deleted when replaced
- **Important**: Uploaded images are excluded from git repository via `.gitignore`

### Git Repository Management
- The `wwwroot/Uploads/TeachingMaterials/` directory structure is preserved in
  git with a `.gitkeep` file
- Actual uploaded images are excluded from version control to:
  - Keep repository size manageable
  - Prevent sensitive content from being committed
  - Avoid merge conflicts with binary files
- When deploying to new environments, ensure the upload directory has proper write permissions

### Database Schema
- New field: `TeachingMaterialImagePath` (VARCHAR(255)) added to the Course table
- Stores the relative path to the uploaded image file

### Security
- File type validation prevents uploading of non-image files
- File size validation prevents uploads larger than 5MB
- Only authenticated users with appropriate roles can upload images

### Authorization
- The application does not currently configure user sign-in or role-based
  authorization. Uploads and CRUD actions follow the existing application
  authorization behavior.

## Troubleshooting

### Common Issues

1. **"File too large" error**: Ensure your image is under 5MB
2. **"Invalid file type" error**: Only JPG, JPEG, PNG, GIF, and BMP files are supported
3. **Upload fails**: Check that the `/Uploads/TeachingMaterials/` directory exists and has write permissions

### Configuration

The equivalent ASP.NET Core settings are in `appsettings.json`:
- `Kestrel:Limits:MaxRequestBodySize` is 10 MB.
- `RequestTimeoutSeconds` is 3600 (one hour).
- Individual teaching-material images are limited to 5 MB by the controller.

## Deployment Considerations

### Initial Setup
1. Ensure `wwwroot/Uploads/TeachingMaterials/` exists on the server.
2. Ensure the application identity can write to that directory.
3. Verify the ASP.NET Core request limit is appropriate for the hosting
   environment.

### File System Permissions
The application needs write access to `wwwroot/Uploads/TeachingMaterials/`.

### Backup Strategy
Since uploaded images are not in version control, implement a backup strategy:
- Regular file system backups of `wwwroot/Uploads/`
- Consider cloud storage integration for production environments
- Document the restore process for disaster recovery

## Future Enhancements

Potential improvements for this feature:
- Image resizing and optimization
- Multiple image support per course
- Image gallery view
- Bulk upload functionality
- Image metadata support (alt text, captions)
