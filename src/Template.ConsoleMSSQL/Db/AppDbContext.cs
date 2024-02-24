using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Template.ConsoleMSSQL.Constraints;
using Template.ConsoleMSSQL.Db.Models;

namespace Template.ConsoleMSSQL.Db;

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
    {
        if (!optionsBuilder.IsConfigured)
        {
            var builder = new ConfigurationBuilder()
                .SetBasePath(AppDomain.CurrentDomain.BaseDirectory)
                .AddJsonFile(Const.ConfigurationFile, optional: false, reloadOnChange: true);
            var config = builder.Build();
            var connectionString = config.GetConnectionString("Default");

            optionsBuilder.UseSqlServer(connectionString);
        }
    }

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
