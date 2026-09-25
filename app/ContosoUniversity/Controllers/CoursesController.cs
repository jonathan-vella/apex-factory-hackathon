using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using System.IO;
using ContosoUniversity.Data;
using ContosoUniversity.Models;
using ContosoUniversity.Services;
using Microsoft.Extensions.Logging;

namespace ContosoUniversity.Controllers
{
    public class CoursesController : BaseController
    {
        private readonly ITeachingMaterialImageStorage _teachingMaterialImageStorage;

        public CoursesController(
            SchoolContext db,
            NotificationService notificationService,
            ITeachingMaterialImageStorage teachingMaterialImageStorage,
            ILogger<CoursesController> logger)
            : base(db, notificationService, logger)
        {
            _teachingMaterialImageStorage = teachingMaterialImageStorage;
        }

        // GET: Courses
        public ActionResult Index()
        {
            var courses = db.Courses.Include(c => c.Department);
            return View(courses.ToList());
        }

        // GET: Courses/Details/5
        public ActionResult Details(int? id)
        {
            if (id == null)
            {
                return BadRequest();
            }
            Course course = db.Courses.Include(c => c.Department).Where(c => c.CourseID == id).Single();
            if (course == null)
            {
                return NotFound();
            }
            return View(course);
        }

        // GET: Courses/Create
        public ActionResult Create()
        {
            ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name");
            return View(new Course());
        }

        // POST: Courses/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(
            [Bind("CourseID,Title,Credits,DepartmentID,TeachingMaterialImagePath")] Course course,
            IFormFile teachingMaterialImage,
            CancellationToken cancellationToken)
        {
            if (ModelState.IsValid)
            {
                // Handle file upload if an image is provided
                if (teachingMaterialImage != null && teachingMaterialImage.Length > 0)
                {
                    // Validate file type
                    var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".bmp" };
                    var fileExtension = Path.GetExtension(teachingMaterialImage.FileName).ToLowerInvariant();
                    
                    if (!allowedExtensions.Contains(fileExtension))
                    {
                        ModelState.AddModelError("teachingMaterialImage", "Please upload a valid image file (jpg, jpeg, png, gif, bmp).");
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }

                    // Validate file size (max 5MB)
                    if (teachingMaterialImage.Length > 5 * 1024 * 1024)
                    {
                        ModelState.AddModelError("teachingMaterialImage", "File size must be less than 5MB.");
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }

                    try
                    {
                        using (var stream = teachingMaterialImage.OpenReadStream())
                        {
                            course.TeachingMaterialImagePath = await _teachingMaterialImageStorage.UploadAsync(
                                course.CourseID,
                                fileExtension,
                                stream,
                                cancellationToken);
                        }
                    }
                    catch (Exception ex)
                    {
                        ModelState.AddModelError("teachingMaterialImage", "Error uploading file: " + ex.Message);
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }
                }

                db.Courses.Add(course);
                await db.SaveChangesAsync(cancellationToken);
                
                // Send notification for course creation
                await SendEntityNotificationAsync("Course", course.CourseID.ToString(), course.Title, EntityOperation.CREATE);
                
                return RedirectToAction("Index");
            }

            ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
            return View(course);
        }

        // GET: Courses/Edit/5
        public ActionResult Edit(int? id)
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
            ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
            return View(course);
        }

        // POST: Courses/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(
            [Bind("CourseID,Title,Credits,DepartmentID,TeachingMaterialImagePath")] Course course,
            IFormFile teachingMaterialImage,
            CancellationToken cancellationToken)
        {
            if (ModelState.IsValid)
            {
                var existingCourse = await db.Courses
                    .AsNoTracking()
                    .SingleOrDefaultAsync(c => c.CourseID == course.CourseID, cancellationToken);
                if (existingCourse == null)
                {
                    return NotFound();
                }

                var previousImagePath = existingCourse.TeachingMaterialImagePath;
                course.TeachingMaterialImagePath = previousImagePath;

                // Handle file upload if a new image is provided
                if (teachingMaterialImage != null && teachingMaterialImage.Length > 0)
                {
                    // Validate file type
                    var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".bmp" };
                    var fileExtension = Path.GetExtension(teachingMaterialImage.FileName).ToLowerInvariant();
                    
                    if (!allowedExtensions.Contains(fileExtension))
                    {
                        ModelState.AddModelError("teachingMaterialImage", "Please upload a valid image file (jpg, jpeg, png, gif, bmp).");
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }

                    // Validate file size (max 5MB)
                    if (teachingMaterialImage.Length > 5 * 1024 * 1024)
                    {
                        ModelState.AddModelError("teachingMaterialImage", "File size must be less than 5MB.");
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }

                    try
                    {
                        using (var stream = teachingMaterialImage.OpenReadStream())
                        {
                            course.TeachingMaterialImagePath = await _teachingMaterialImageStorage.UploadAsync(
                                course.CourseID,
                                fileExtension,
                                stream,
                                cancellationToken);
                        }
                    }
                    catch (Exception ex)
                    {
                        ModelState.AddModelError("teachingMaterialImage", "Error uploading file: " + ex.Message);
                        ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
                        return View(course);
                    }
                }

                db.Entry(course).State = EntityState.Modified;
                await db.SaveChangesAsync(cancellationToken);

                if (teachingMaterialImage != null && teachingMaterialImage.Length > 0)
                {
                    await TryDeleteTeachingMaterialImageAsync(
                        course.CourseID,
                        previousImagePath,
                        cancellationToken);
                }
                
                // Send notification for course update
                await SendEntityNotificationAsync("Course", course.CourseID.ToString(), course.Title, EntityOperation.UPDATE);
                
                return RedirectToAction("Index");
            }
            ViewBag.DepartmentID = new SelectList(db.Departments, "DepartmentID", "Name", course.DepartmentID);
            return View(course);
        }

        // GET: Courses/Delete/5
        public ActionResult Delete(int? id)
        {
            if (id == null)
            {
                return BadRequest();
            }
            Course course = db.Courses.Include(c => c.Department).Where(c => c.CourseID == id).Single();
            if (course == null)
            {
                return NotFound();
            }
            return View(course);
        }

        // POST: Courses/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id, CancellationToken cancellationToken)
        {
            Course course = db.Courses.Find(id);
            var courseTitle = course.Title;
            
            // Delete associated image file if it exists
            if (!string.IsNullOrEmpty(course.TeachingMaterialImagePath))
            {
                await TryDeleteTeachingMaterialImageAsync(
                    course.CourseID,
                    course.TeachingMaterialImagePath,
                    cancellationToken);
            }
            
            db.Courses.Remove(course);
            await db.SaveChangesAsync(cancellationToken);
            
            // Send notification for course deletion
            await SendEntityNotificationAsync("Course", id.ToString(), courseTitle, EntityOperation.DELETE);
            
            return RedirectToAction("Index");
        }

        // GET: Courses/TeachingMaterialImage
        [HttpGet]
        public async Task<IActionResult> TeachingMaterialImage(
            string imagePath,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(imagePath))
            {
                return BadRequest();
            }

            var image = await _teachingMaterialImageStorage.DownloadAsync(imagePath, cancellationToken);
            if (image == null)
            {
                return NotFound();
            }

            return File(image.Content, image.ContentType);
        }

        private async Task TryDeleteTeachingMaterialImageAsync(
            int courseId,
            string imagePath,
            CancellationToken cancellationToken)
        {
            try
            {
                await _teachingMaterialImageStorage.DeleteAsync(courseId, imagePath, cancellationToken);
            }
            catch (Exception ex)
            {
                // Image cleanup must not prevent the course from being saved or deleted.
                logger.LogError(
                    ex,
                    "Error deleting teaching-material image {ImagePath} for course {CourseId}",
                    imagePath,
                    courseId);
            }
        }
    }
}
