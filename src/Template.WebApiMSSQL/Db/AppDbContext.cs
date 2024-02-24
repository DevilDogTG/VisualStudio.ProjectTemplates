using Microsoft.EntityFrameworkCore;
using Template.WebApiMSSQL.Db.Models;

namespace Template.WebApiMSSQL.Db;

public partial class AppDbContext : DbContext
{
    public AppDbContext()
    {
    }

    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<TbName> TbNames { get; set; }

    public virtual DbSet<TbNameOther> TbNameOthers { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        => optionsBuilder.UseSqlServer("Name=ConnectionStrings:Default");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<TbName>(entity =>
        {
            entity.ToTable("TbName");

            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .IsUnicode(false);
        });

        modelBuilder.Entity<TbNameOther>(entity =>
        {
            entity.ToTable("TbNameOther");

            entity.Property(e => e.NameOther)
                .HasMaxLength(100)
                .IsUnicode(false);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
