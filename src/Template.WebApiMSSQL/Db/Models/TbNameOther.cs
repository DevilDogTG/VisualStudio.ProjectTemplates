using System;
using System.Collections.Generic;

namespace Template.WebApiMSSQL.Db.Models;

public partial class TbNameOther
{
    public int Id { get; set; }

    public string NameOther { get; set; } = null!;
}
