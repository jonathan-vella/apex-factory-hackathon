using System;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Azure;
using ContosoUniversity.Data;
using ContosoUniversity.Models;
using ContosoUniversity.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.EntityFrameworkCore;

namespace ContosoUniversity.Controllers
{
    public class CoursesController : BaseController
    {
        private const long MaximumUploadSize = 5 * 1024 * 1024;
        private const string StoredImagePathPrefix = "~/Uploads/TeachingMaterials/";
        private static readonly FileExtensionContentTypeProvider ContentTypeProvider = new();
        private readonly ITeachingMaterialStorage teachingMaterialStorage;

        public CoursesController(
            SchoolContext db,
            INotificationService notificationService,
            ITeachingMaterialStorage teachingMaterialStorage)
            : base(db, notificationService)
        {
            this.teachingMaterialStorage = teachingMaterialStorage;
        }

        // GET: Courses
        public IActionResult Index()
        {
            var courses = db.Courses.Include(c => c.Department);
            return View(courses.ToList());
        }

        // GET: Courses/Details/5
        public IActionResult Details(int? id)
        {
            if (id == null)
            {
                return BadRequest();
            }

            Course course = db.Courses
                .Include(c => c.Department)
                .SingleOrDefault(c => c.CourseID == id);
            if (course == null)
            {
                return NotFound();
            }

            return View(course);
        }

        // GET: Courses/Create
        public IActionResult Create()
        {
            ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name");
            return View(new Course());
        }

        // POST: Courses/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(
            [Bind("CourseID,Title,Credits,DepartmentID,TeachingMaterialImagePath")] Course course,
            IFormFile teachingMaterialImage)
        {
            if (ModelState.IsValid && teachingMaterialImage != null && teachingMaterialImage.Length > 0)
            {
                if (!TryValidateUpload(teachingMaterialImage, out var fileExtension))
                {
                    PopulateDepartments(course.DepartmentID);
                    return View(course);
                }

                try
                {
                    var fileName = $"course_{course.CourseID}_{Guid.NewGuid()}{fileExtension}";
                    using var stream = teachingMaterialImage.OpenReadStream();
                    await teachingMaterialStorage.UploadAsync(fileName, stream, GetContentType(fileName));
                    course.TeachingMaterialImagePath = StoredImagePathPrefix + fileName;
                }
                catch (Exception)
                {
                    ModelState.AddModelError("teachingMaterialImage", "Error uploading file. Please try again.");
                    PopulateDepartments(course.DepartmentID);
                    return View(course);
                }
            }

            if (ModelState.IsValid)
            {
                db.Courses.Add(course);
                db.SaveChanges();

                SendEntityNotification("Course", course.CourseID.ToString(), course.Title, EntityOperation.CREATE);

                return RedirectToAction("Index");
            }

            PopulateDepartments(course.DepartmentID);
            return View(course);
        }

        // GET: Courses/Edit/5
        public IActionResult Edit(int? id)
        {
            if (id == null)
            {
                return BadRequest();
            }

            Course course = db.Courses.Find(id);
            if (course == null)
            {
                return NotFound();
            }

            PopulateDepartments(course.DepartmentID);
            return View(course);
        }

        // POST: Courses/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(
            [Bind("CourseID,Title,Credits,DepartmentID,TeachingMaterialImagePath")] Course course,
            IFormFile teachingMaterialImage)
        {
            if (ModelState.IsValid && teachingMaterialImage != null && teachingMaterialImage.Length > 0)
            {
                if (!TryValidateUpload(teachingMaterialImage, out var fileExtension))
                {
                    PopulateDepartments(course.DepartmentID);
                    return View(course);
                }

                try
                {
                    var fileName = $"course_{course.CourseID}_{Guid.NewGuid()}{fileExtension}";
                    await DeleteStoredFileAsync(course.TeachingMaterialImagePath);

                    using var stream = teachingMaterialImage.OpenReadStream();
                    await teachingMaterialStorage.UploadAsync(fileName, stream, GetContentType(fileName));
                    course.TeachingMaterialImagePath = StoredImagePathPrefix + fileName;
                }
                catch (Exception)
                {
                    ModelState.AddModelError("teachingMaterialImage", "Error uploading file. Please try again.");
                    PopulateDepartments(course.DepartmentID);
                    return View(course);
                }
            }

            if (ModelState.IsValid)
            {
                db.Entry(course).State = EntityState.Modified;
                db.SaveChanges();

                SendEntityNotification("Course", course.CourseID.ToString(), course.Title, EntityOperation.UPDATE);

                return RedirectToAction("Index");
            }

            PopulateDepartments(course.DepartmentID);
            return View(course);
        }

        // GET: Courses/Delete/5
        public IActionResult Delete(int? id)
        {
            if (id == null)
            {
                return BadRequest();
            }

            Course course = db.Courses
                .Include(c => c.Department)
                .SingleOrDefault(c => c.CourseID == id);
            if (course == null)
            {
                return NotFound();
            }

            return View(course);
        }

        [HttpGet("/Uploads/TeachingMaterials/{fileName}")]
        public async Task<IActionResult> TeachingMaterial(string fileName, CancellationToken cancellationToken)
        {
            if (!IsValidFileName(fileName))
            {
                return NotFound();
            }

            try
            {
                var teachingMaterial = await teachingMaterialStorage.DownloadAsync(fileName, cancellationToken);
                return teachingMaterial == null
                    ? NotFound()
                    : File(teachingMaterial.Content, teachingMaterial.ContentType);
            }
            catch (InvalidOperationException)
            {
                return StatusCode(StatusCodes.Status503ServiceUnavailable);
            }
            catch (RequestFailedException)
            {
                return StatusCode(StatusCodes.Status503ServiceUnavailable);
            }
        }

        // POST: Courses/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            Course course = db.Courses.Find(id);
            if (course == null)
            {
                return NotFound();
            }

            var courseTitle = course.Title;

            if (!string.IsNullOrEmpty(course.TeachingMaterialImagePath))
            {
                try
                {
                    await DeleteStoredFileAsync(course.TeachingMaterialImagePath);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Error deleting file: {ex.Message}");
                }
            }

            db.Courses.Remove(course);
            db.SaveChanges();

            SendEntityNotification("Course", id.ToString(), courseTitle, EntityOperation.DELETE);

            return RedirectToAction("Index");
        }

        private bool TryValidateUpload(IFormFile upload, out string fileExtension)
        {
            fileExtension = Path.GetExtension(upload.FileName).ToLowerInvariant();
            if (!TeachingMaterialFileName.IsAllowedExtension(fileExtension))
            {
                ModelState.AddModelError("teachingMaterialImage", "Please upload a valid image file (jpg, jpeg, png, gif, bmp).");
                return false;
            }

            if (upload.Length > MaximumUploadSize)
            {
                ModelState.AddModelError("teachingMaterialImage", "File size must be less than 5MB.");
                return false;
            }

            return true;
        }

        private async Task DeleteStoredFileAsync(string virtualPath)
        {
            if (TryGetStoredFileName(virtualPath, out var fileName))
            {
                await teachingMaterialStorage.DeleteAsync(fileName);
            }
        }

        private static bool TryGetStoredFileName(string virtualPath, out string fileName)
        {
            fileName = string.Empty;
            if (string.IsNullOrEmpty(virtualPath) ||
                !virtualPath.StartsWith(StoredImagePathPrefix, StringComparison.Ordinal))
            {
                return false;
            }

            var candidate = virtualPath[StoredImagePathPrefix.Length..];
            if (!IsValidFileName(candidate))
            {
                return false;
            }

            fileName = candidate;
            return true;
        }

        private static bool IsValidFileName(string fileName)
        {
            return TeachingMaterialFileName.IsValid(fileName);
        }

        private static string GetContentType(string fileName)
        {
            return ContentTypeProvider.TryGetContentType(fileName, out var contentType)
                ? contentType
                : "application/octet-stream";
        }

        private void PopulateDepartments(int? selectedDepartment = null)
        {
            ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", selectedDepartment);
        }
    }
}
