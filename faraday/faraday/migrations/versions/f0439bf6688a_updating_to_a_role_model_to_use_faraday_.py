"""Updating to a Role model to use faraday security RBAC

Revision ID: f0439bf6688a
Revises: 18891ca61db6
Create Date: 2021-05-26 18:38:23.267138+00:00

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'f0439bf6688a'
down_revision = '18891ca61db6'
branch_labels = None
depends_on = None

ROLES = ['admin', 'pentester', 'client', 'asset_owner']


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('faraday_role',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('name', sa.String(length=80), nullable=True),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('name')
    )
    op.create_table('roles_users',
    sa.Column('user_id', sa.Integer(), nullable=True),
    sa.Column('role_id', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['role_id'], ['faraday_role.id'], ),
    sa.ForeignKeyConstraint(['user_id'], ['faraday_user.id'], )
    )

    op.execute("INSERT INTO faraday_role(name) VALUES ('admin'),('pentester'),('client'),('asset_owner');")

    roles_users = sa.table(
        'roles_users',
        sa.column('user_id', sa.Integer),
        sa.column('role_id', sa.Integer)
    )

    conn = op.get_bind()
    res = conn.execute('SELECT name, id FROM faraday_role').fetchall()
    roles = dict(res)

    res = conn.execute('SELECT id, role FROM faraday_user').fetchall()

    for _id, role in res:
        op.execute(
            roles_users.insert().values({'user_id': _id, 'role_id': roles[role]})
        )

    op.drop_column('faraday_user', 'role')
    op.alter_column('vulnerability', 'risk',
               existing_type=sa.REAL(),
               type_=sa.Float(precision=3, asdecimal=1),
               existing_nullable=True)
    op.alter_column('vulnerability_template', 'risk',
               existing_type=sa.REAL(),
               type_=sa.Float(precision=3, asdecimal=1),
               existing_nullable=True)
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.alter_column('vulnerability_template', 'risk',
               existing_type=sa.Float(precision=3, asdecimal=1),
               type_=sa.REAL(),
               existing_nullable=True)
    op.alter_column('vulnerability', 'risk',
               existing_type=sa.Float(precision=3, asdecimal=1),
               type_=sa.REAL(),
               existing_nullable=True)
    op.add_column('faraday_user', sa.Column('role', postgresql.ENUM('admin', 'pentester', 'client', 'asset_owner',
                                                                    name='user_roles'),
                                            autoincrement=False,
                                            nullable=True))

    users = sa.table(
        'faraday_user',
        sa.column('id', sa.Integer),
        sa.Column('role', sa.Enum(*ROLES, 'user_roles')),
    )

    conn = op.get_bind()
    res = conn.execute('SELECT id, name FROM faraday_role').fetchall()
    roles = dict(res)

    res = conn.execute('SELECT user_id, role_id FROM roles_users').fetchall()

    for _id, role_id in res:
        op.execute(
            users.update().where(users.c.id == _id).values({'role': roles[role_id]})
        )

    op.alter_column('faraday_user', 'role', nullable=False)

    op.drop_table('roles_users')
    op.drop_table('faraday_role')
    # ### end Alembic commands ###
