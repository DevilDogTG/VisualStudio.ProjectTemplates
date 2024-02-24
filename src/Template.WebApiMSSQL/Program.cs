using Serilog;
using Template.WebApiMSSQL.Constraints;
using Template.WebApiMSSQL.Interfaces;
using Template.WebApiMSSQL.Models;

var builder = WebApplication.CreateBuilder(args);
var config = builder.Configuration.GetSection(Const.ConfigurationKey).Get<ConfigurationModel>();
builder.Host.UseSerilog((context, loggerConfiguration) => loggerConfiguration
    .ReadFrom.Configuration(context.Configuration)
    .Enrich.FromLogContext());
builder.Services.AddSingleton<IConfigurationModel>(config);
builder.Services.AddControllers();
builder.Services.AddHttpContextAccessor();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

//Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();
app.Run();
