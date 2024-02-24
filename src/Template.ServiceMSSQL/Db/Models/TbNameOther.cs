using System;
using System.Collections.Generic;

namespace Template.ServiceMSSQL.Db.Models;

public partial class TbNameOther
{
    public int Id { get; set; }

    public string NameOther { get; set; } = null!;
}
