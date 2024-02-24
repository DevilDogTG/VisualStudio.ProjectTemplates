using System;
using System.Collections.Generic;

namespace Template.WebApiMSSQL.Db.Models;

public partial class TbName
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;
}
