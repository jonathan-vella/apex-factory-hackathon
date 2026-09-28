using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using ContosoUniversity.Data;
using ContosoUniversity.Models;
using ContosoUniversity.Services;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace ContosoUniversity.Controllers
{
    public class CoursesController : BaseController
    {
        private const long MaximumUploadSize = 5 * 1024 * 1024;
        private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".bmp" };
        private readonly string uploadsPath;

        public CoursesController(
            SchoolContext db,
            INotificationService notificationService,
            IWebHostEnvironment environment)
            : base(db, notificationService)
        {
            uploadsPath = Path.Combine(environment.ContentRootPath, "Uploads", "TeachingMaterials");
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
                    Directory.CreateDirectory(uploadsPath);
                    var fileName = $"course_{course.CourseID}_{Guid.NewGuid()}{fileExtension}";
                    var filePath = Path.Combine(uploadsPath, fileName);

                    await using var stream = new FileStream(filePath, FileMode.Create);
                    await teachingMaterialImage.CopyToAsync(stream);
                    course.TeachingMaterialImagePath = $"~/Uploads/TeachingMaterials/{fileName}";
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("teachingMaterialImage", "Error uploading file: " + ex.Message);
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
                    Directory.CreateDirectory(uploadsPath);
                    var fileName = $"course_{course.CourseID}_{Guid.NewGuid()}{fileExtension}";
                    var filePath = Path.Combine(uploadsPath, fileName);

                    DeleteStoredFile(course.TeachingMaterialImagePath);

                    await using var stream = new FileStream(filePath, FileMode.Create);
                    await teachingMaterialImage.CopyToAsync(stream);
                    course.TeachingMaterialImagePath = $"~/Uploads/TeachingMaterials/{fileName}";
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("teachingMaterialImage", "Error uploading file: " + ex.Message);
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

        // POST: Courses/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public IActionResult DeleteConfirmed(int id)
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
                    DeleteStoredFile(course.TeachingMaterialImagePath);
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
            if (!AllowedExtensions.Contains(fileExtension))
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

        private void DeleteStoredFile(string virtualPath)
        {
            var fileName = Path.GetFileName(virtualPath);
            if (!string.IsNullOrEmpty(fileName))
            {
                var filePath = Path.Combine(uploadsPath, fileName);
                if (System.IO.File.Exists(filePath))
                {
                    System.IO.File.Delete(filePath);
                }
            }
        }

        private void PopulateDepartments(int? selectedDepartment = null)
        {
            ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", selectedDepartment);
        }
    }
}
